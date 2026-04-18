#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib import error, request


HOST = "0.0.0.0"
PORT = int(os.getenv("ALERT_WEBHOOK_PORT", "5001"))
LOG_PATH = Path(os.getenv("ALERT_WEBHOOK_LOG_PATH", "/data/alerts.jsonl"))
FORWARD_LOG_PATH = Path(os.getenv("ALERT_FORWARD_LOG_PATH", "/data/forward.jsonl"))
FORWARD_WEBHOOK_URL = os.getenv("ALERT_FORWARD_WEBHOOK_URL", "").strip()
FORWARD_WEBHOOK_URL_WARNING = os.getenv("ALERT_FORWARD_WEBHOOK_URL_WARNING", "").strip()
FORWARD_WEBHOOK_URL_CRITICAL = os.getenv("ALERT_FORWARD_WEBHOOK_URL_CRITICAL", "").strip()
FORWARD_TIMEOUT_SECONDS = float(os.getenv("ALERT_FORWARD_TIMEOUT_SECONDS", "5"))

PAGERDUTY_EVENTS_URL = os.getenv("ALERT_PAGERDUTY_EVENTS_URL", "https://events.pagerduty.com/v2/enqueue").strip()
PAGERDUTY_ROUTING_KEY = os.getenv("ALERT_PAGERDUTY_ROUTING_KEY", "").strip()
PAGERDUTY_ENABLED_CHANNELS = {
    item.strip() for item in os.getenv("ALERT_PAGERDUTY_ENABLED_CHANNELS", "critical").split(",") if item.strip()
}

SILENCE_WINDOW_DEFAULT_SECONDS = int(os.getenv("ALERT_SILENCE_WINDOW_SECONDS", "90"))
SILENCE_WINDOW_WARNING_SECONDS = int(
    os.getenv("ALERT_SILENCE_WINDOW_WARNING_SECONDS", str(SILENCE_WINDOW_DEFAULT_SECONDS))
)
SILENCE_WINDOW_CRITICAL_SECONDS = int(
    os.getenv("ALERT_SILENCE_WINDOW_CRITICAL_SECONDS", str(SILENCE_WINDOW_DEFAULT_SECONDS))
)
SILENCE_WINDOW_GENERIC_SECONDS = int(
    os.getenv("ALERT_SILENCE_WINDOW_GENERIC_SECONDS", str(SILENCE_WINDOW_DEFAULT_SECONDS))
)

LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
FORWARD_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

# In-memory dedup/silence state for relay process lifetime.
LAST_FORWARDED_AT: dict[str, float] = {}

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
    "silence_skipped_total": 0,
    "silence_skipped_warning_total": 0,
    "silence_skipped_critical_total": 0,
    "silence_skipped_generic_total": 0,
    "pagerduty_attempt_total": 0,
    "pagerduty_success_total": 0,
    "pagerduty_failed_total": 0,
}


def _append_jsonl(path: Path, payload: dict[str, object]) -> None:
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(payload, ensure_ascii=False) + "\n")


def _now_ts() -> float:
    return datetime.now(timezone.utc).timestamp()


def _silence_window_seconds(channel: str) -> int:
    if channel == "warning":
        return SILENCE_WINDOW_WARNING_SECONDS
    if channel == "critical":
        return SILENCE_WINDOW_CRITICAL_SECONDS
    return SILENCE_WINDOW_GENERIC_SECONDS


def _alerts(payload: dict[str, Any]) -> list[dict[str, Any]]:
    raw = payload.get("alerts", [])
    if isinstance(raw, list):
        return [item for item in raw if isinstance(item, dict)]
    return []


def _make_dedup_key(channel: str, payload: dict[str, Any]) -> str:
    alerts = _alerts(payload)
    parts: list[str] = [channel]
    for alert in alerts:
        labels = alert.get("labels", {}) or {}
        keys = [
            str(labels.get("alertname", "")),
            str(labels.get("service", "")),
            str(labels.get("severity", "")),
            str(labels.get("instance", "")),
            str(labels.get("job", "")),
        ]
        parts.append("|".join(keys))
    if not alerts:
        parts.append(json.dumps(payload, sort_keys=True))
    raw_key = "::".join(sorted(parts))
    return hashlib.sha256(raw_key.encode("utf-8")).hexdigest()


def _is_firing_payload(payload: dict[str, Any]) -> bool:
    status = str(payload.get("status", "")).lower()
    if status == "firing":
        return True
    alerts = _alerts(payload)
    return any(str(item.get("status", "")).lower() == "firing" for item in alerts)


def _should_silence(channel: str, payload: dict[str, Any]) -> tuple[bool, str]:
    if not _is_firing_payload(payload):
        return False, "not firing"

    key = _make_dedup_key(channel, payload)
    window = _silence_window_seconds(channel)
    now = _now_ts()
    last = LAST_FORWARDED_AT.get(key)
    if last is not None and (now - last) < window:
        return True, key

    LAST_FORWARDED_AT[key] = now
    return False, key


def _build_slack_text(payload: dict[str, Any]) -> str:
    alerts = _alerts(payload)
    if not alerts:
        return "[BlogSnap] malformed alert payload"

    lines = [f"[BlogSnap Alert] count={len(alerts)}"]
    for idx, alert in enumerate(alerts[:10], start=1):
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


def _http_post_json(url: str, payload: dict[str, Any]) -> tuple[bool, str]:
    body = json.dumps(payload).encode("utf-8")
    req = request.Request(
        url,
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


def _forward_to_slack_webhook(payload: dict[str, Any], channel: str) -> tuple[bool | None, str]:
    forward_url = _resolve_forward_url(channel)
    if not forward_url:
        return None, "forward url not configured"

    return _http_post_json(forward_url, {"text": _build_slack_text(payload)})


def _forward_to_pagerduty(payload: dict[str, Any], channel: str) -> tuple[bool | None, str]:
    if not PAGERDUTY_ROUTING_KEY:
        return None, "pagerduty routing key not configured"
    if channel not in PAGERDUTY_ENABLED_CHANNELS:
        return None, "channel disabled for pagerduty"

    alerts = _alerts(payload)
    if not alerts:
        return False, "no alerts in payload"

    all_ok = True
    messages: list[str] = []
    for alert in alerts[:10]:
        labels = alert.get("labels", {}) or {}
        annotations = alert.get("annotations", {}) or {}
        alertname = str(labels.get("alertname", "unknown"))
        service = str(labels.get("service", "unknown"))
        severity = str(labels.get("severity", channel))
        status = str(alert.get("status", payload.get("status", "firing"))).lower()
        summary = str(annotations.get("summary", f"BlogSnap alert: {alertname}"))

        dedup_key_raw = f"{alertname}|{service}|{severity}"
        dedup_key = hashlib.sha256(dedup_key_raw.encode("utf-8")).hexdigest()

        event_action = "trigger" if status != "resolved" else "resolve"
        pd_payload = {
            "routing_key": PAGERDUTY_ROUTING_KEY,
            "event_action": event_action,
            "dedup_key": dedup_key,
            "payload": {
                "summary": summary,
                "source": service,
                "severity": "critical" if severity == "critical" else "warning",
                "custom_details": {
                    "labels": labels,
                    "annotations": annotations,
                    "channel": channel,
                },
            },
        }

        ok, msg = _http_post_json(PAGERDUTY_EVENTS_URL, pd_payload)
        messages.append(msg)
        all_ok = all_ok and ok

    return all_ok, "; ".join(messages) if messages else "no events"


def _inc_channel_stats(channel: str, success: bool) -> None:
    if channel == "warning":
        if success:
            STATS["forward_warning_success_total"] += 1
        else:
            STATS["forward_warning_failed_total"] += 1
    elif channel == "critical":
        if success:
            STATS["forward_critical_success_total"] += 1
        else:
            STATS["forward_critical_failed_total"] += 1
    else:
        if success:
            STATS["forward_generic_success_total"] += 1
        else:
            STATS["forward_generic_failed_total"] += 1


def _inc_silence_stats(channel: str) -> None:
    STATS["silence_skipped_total"] += 1
    if channel == "warning":
        STATS["silence_skipped_warning_total"] += 1
    elif channel == "critical":
        STATS["silence_skipped_critical_total"] += 1
    else:
        STATS["silence_skipped_generic_total"] += 1


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
                        or PAGERDUTY_ROUTING_KEY
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
        silenced, silence_key = _should_silence(channel, payload)

        event = {
            "received_at": datetime.now(timezone.utc).isoformat(),
            "client": self.client_address[0],
            "channel": channel,
            "silenced": silenced,
            "silence_key": silence_key,
            "payload": payload,
        }
        _append_jsonl(LOG_PATH, event)

        if silenced:
            _inc_silence_stats(channel)
            self._send_json(200, {"status": "accepted", "silenced": True})
            return

        slack_ok, slack_msg = _forward_to_slack_webhook(payload, channel)
        pager_ok, pager_msg = _forward_to_pagerduty(payload, channel)

        attempted = (slack_ok is not None) or (pager_ok is not None)
        success_parts = [val for val in (slack_ok, pager_ok) if val is not None]
        success = bool(success_parts) and all(success_parts)

        if attempted:
            STATS["forward_attempt_total"] += 1
            if success:
                STATS["forward_success_total"] += 1
                _inc_channel_stats(channel, True)
            else:
                STATS["forward_failed_total"] += 1
                _inc_channel_stats(channel, False)

        if pager_ok is not None:
            STATS["pagerduty_attempt_total"] += 1
            if pager_ok:
                STATS["pagerduty_success_total"] += 1
            else:
                STATS["pagerduty_failed_total"] += 1

        _append_jsonl(
            FORWARD_LOG_PATH,
            {
                "received_at": event["received_at"],
                "channel": channel,
                "slack_ok": slack_ok,
                "slack_message": slack_msg,
                "pagerduty_ok": pager_ok,
                "pagerduty_message": pager_msg,
                "silenced": False,
            },
        )

        self._send_json(
            200,
            {
                "status": "accepted",
                "silenced": False,
                "forward_attempted": attempted,
                "forwarded": success if attempted else None,
            },
        )

    def log_message(self, fmt: str, *args: object) -> None:
        return


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    has_forward = bool(
        FORWARD_WEBHOOK_URL
        or FORWARD_WEBHOOK_URL_WARNING
        or FORWARD_WEBHOOK_URL_CRITICAL
        or PAGERDUTY_ROUTING_KEY
    )
    print(
        f"[alert-webhook] listening on {HOST}:{PORT}, log={LOG_PATH}, forward={has_forward}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
