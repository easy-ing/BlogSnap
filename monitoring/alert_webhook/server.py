#!/usr/bin/env python3
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib import error, request


HOST = "0.0.0.0"
PORT = int(os.getenv("ALERT_WEBHOOK_PORT", "5001"))
LOG_PATH = Path(os.getenv("ALERT_WEBHOOK_LOG_PATH", "/data/alerts.jsonl"))
FORWARD_LOG_PATH = Path(os.getenv("ALERT_FORWARD_LOG_PATH", "/data/forward.jsonl"))
FORWARD_WEBHOOK_URL = os.getenv("ALERT_FORWARD_WEBHOOK_URL", "").strip()
FORWARD_WEBHOOK_URL_WARNING = os.getenv("ALERT_FORWARD_WEBHOOK_URL_WARNING", "").strip()
FORWARD_WEBHOOK_URL_CRITICAL = os.getenv("ALERT_FORWARD_WEBHOOK_URL_CRITICAL", "").strip()
FORWARD_TIMEOUT_SECONDS = float(os.getenv("ALERT_FORWARD_TIMEOUT_SECONDS", "5"))
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
FORWARD_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

STATS: dict[str, int] = {
    "alerts_received_total": 0,
    "forward_attempt_total": 0,
    "forward_success_total": 0,
    "forward_failed_total": 0,
    "forward_warning_success_total": 0,
    "forward_warning_failed_total": 0,
    "forward_critical_success_total": 0,
    "forward_critical_failed_total": 0,
    "forward_generic_success_total": 0,
    "forward_generic_failed_total": 0,
}


def _append_jsonl(path: Path, payload: dict[str, object]) -> None:
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(payload, ensure_ascii=False) + "\n")


def _build_slack_text(payload: dict[str, object]) -> str:
    alerts = payload.get("alerts", [])
    if not isinstance(alerts, list):
        return "[BlogSnap] malformed alert payload"

    lines = [f"[BlogSnap Alert] count={len(alerts)}"]
    for idx, alert in enumerate(alerts[:10], start=1):
        if not isinstance(alert, dict):
            continue
        labels = alert.get("labels", {}) or {}
        annotations = alert.get("annotations", {}) or {}
        status = alert.get("status", "unknown")
        name = labels.get("alertname", "unknown")
        severity = labels.get("severity", "unknown")
        summary = annotations.get("summary", "")
        line = f"{idx}. {name} ({severity}, {status})"
        if summary:
            line += f" - {summary}"
        lines.append(line)
    return "\n".join(lines)


def _resolve_forward_url(channel: str) -> str:
    if channel == "warning" and FORWARD_WEBHOOK_URL_WARNING:
        return FORWARD_WEBHOOK_URL_WARNING
    if channel == "critical" and FORWARD_WEBHOOK_URL_CRITICAL:
        return FORWARD_WEBHOOK_URL_CRITICAL
    return FORWARD_WEBHOOK_URL


def _forward_to_webhook(payload: dict[str, object], channel: str) -> tuple[bool, str]:
    forward_url = _resolve_forward_url(channel)
    if not forward_url:
        return False, "forward url not configured"

    outbound = {"text": _build_slack_text(payload)}
    body = json.dumps(outbound).encode("utf-8")
    req = request.Request(
        forward_url,
        data=body,
        method="POST",
        headers={"Content-Type": "application/json"},
    )
    try:
        with request.urlopen(req, timeout=FORWARD_TIMEOUT_SECONDS) as resp:  # nosec B310
            code = int(getattr(resp, "status", 200))
            if code < 200 or code >= 300:
                return False, f"unexpected status {code}"
    except error.URLError as exc:
        return False, f"url error: {exc}"
    except TimeoutError:
        return False, "timeout"
    return True, "ok"


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, code: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path in ("/", "/health", "/ready"):
            self._send_json(
                200,
                {
                    "status": "ok",
                    "forward_configured": bool(
                        FORWARD_WEBHOOK_URL
                        or FORWARD_WEBHOOK_URL_WARNING
                        or FORWARD_WEBHOOK_URL_CRITICAL
                    ),
                },
            )
            return
        if self.path == "/stats":
            self._send_json(200, {"status": "ok", "stats": STATS})
            return
        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        if self.path not in ("/alerts", "/alerts/warning", "/alerts/critical"):
            self._send_json(404, {"error": "not found"})
            return

        channel = "generic"
        if self.path == "/alerts/warning":
            channel = "warning"
        elif self.path == "/alerts/critical":
            channel = "critical"

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            self._send_json(400, {"error": "invalid json"})
            return

        STATS["alerts_received_total"] += 1
        event = {
            "received_at": datetime.now(timezone.utc).isoformat(),
            "client": self.client_address[0],
            "channel": channel,
            "payload": payload,
        }
        _append_jsonl(LOG_PATH, event)

        forward_ok, message = _forward_to_webhook(payload, channel)
        if _resolve_forward_url(channel):
            STATS["forward_attempt_total"] += 1
            if forward_ok:
                STATS["forward_success_total"] += 1
            else:
                STATS["forward_failed_total"] += 1
            if channel == "warning":
                if forward_ok:
                    STATS["forward_warning_success_total"] += 1
                else:
                    STATS["forward_warning_failed_total"] += 1
            elif channel == "critical":
                if forward_ok:
                    STATS["forward_critical_success_total"] += 1
                else:
                    STATS["forward_critical_failed_total"] += 1
            else:
                if forward_ok:
                    STATS["forward_generic_success_total"] += 1
                else:
                    STATS["forward_generic_failed_total"] += 1

            _append_jsonl(
                FORWARD_LOG_PATH,
                {
                    "received_at": event["received_at"],
                    "channel": channel,
                    "forward_ok": forward_ok,
                    "message": message,
                },
            )

        self._send_json(200, {"status": "accepted", "forwarded": forward_ok if FORWARD_WEBHOOK_URL else None})

    def log_message(self, fmt: str, *args: object) -> None:
        return


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    has_forward = bool(FORWARD_WEBHOOK_URL or FORWARD_WEBHOOK_URL_WARNING or FORWARD_WEBHOOK_URL_CRITICAL)
    print(
        f"[alert-webhook] listening on {HOST}:{PORT}, log={LOG_PATH}, forward={has_forward}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
