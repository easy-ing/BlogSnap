#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_MD="$REPORT_DIR/day46-alert-noise-review-$TS.md"
REPORT_JSON="$REPORT_DIR/day46-alert-noise-review-$TS.json"

run_step() {
  local name="$1"
  shift
  echo "[STEP] $name"
  if "$@"; then
    echo "- [x] $name" >> "$REPORT_MD"
  else
    echo "- [ ] $name (FAILED)" >> "$REPORT_MD"
    echo "[ERROR] step failed: $name"
    exit 1
  fi
}

echo "# Day46 Alert Noise Review" > "$REPORT_MD"
echo "" >> "$REPORT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_MD"
echo "- env_file: $ENV_FILE" >> "$REPORT_MD"
echo "" >> "$REPORT_MD"

run_step "Stack up" ./scripts/day7_run_stack.sh
run_step "Env check" ./scripts/day12_env_check.sh "$ENV_FILE"
run_step "Seed alert routing samples" ./scripts/day12_alert_routing_demo.sh

STATS_JSON="$(curl -fsS http://127.0.0.1:5001/stats)"
printf '%s\n' "$STATS_JSON" > /tmp/day46_stats.json

python3 - <<'PY' "$REPORT_JSON" "$REPORT_MD" /tmp/day46_stats.json
import json
import sys
from pathlib import Path

out_json = Path(sys.argv[1])
out_md = Path(sys.argv[2])
stats_path = Path(sys.argv[3])

payload = json.loads(stats_path.read_text(encoding="utf-8"))
stats = payload.get("stats", {})

alerts = int(stats.get("alerts_received_total", 0))
attempt = int(stats.get("forward_attempt_total", 0))
success = int(stats.get("forward_success_total", 0))
failed = int(stats.get("forward_failed_total", 0))
silence = int(stats.get("silence_skipped_total", 0))

forward_success_rate = (success / attempt) if attempt else 1.0
noise_ratio = (silence / alerts) if alerts else 0.0
fail_ratio = (failed / attempt) if attempt else 0.0

recommendations = []
if noise_ratio > 0.5:
    recommendations.append("silence 비율이 높습니다. ALERT_SILENCE_WINDOW_* 값을 줄여 과도한 억제를 완화하세요.")
elif noise_ratio < 0.1:
    recommendations.append("silence 비율이 낮습니다. 중복 경보가 많다면 ALERT_SILENCE_WINDOW_* 값을 늘리세요.")
else:
    recommendations.append("silence 비율은 적정 범위입니다.")

if forward_success_rate < 0.98:
    recommendations.append("forward 성공률이 낮습니다. 웹훅 엔드포인트/타임아웃(ALERT_FORWARD_TIMEOUT_SECONDS) 점검이 필요합니다.")
else:
    recommendations.append("forward 성공률은 양호합니다.")

if fail_ratio > 0.05:
    recommendations.append("forward 실패율이 높습니다. warning/critical 채널별 URL 유효성 확인을 권장합니다.")

result = {
    "status": "ok",
    "metrics": {
        "alerts_received_total": alerts,
        "forward_attempt_total": attempt,
        "forward_success_total": success,
        "forward_failed_total": failed,
        "silence_skipped_total": silence,
        "forward_success_rate": round(forward_success_rate, 4),
        "forward_fail_ratio": round(fail_ratio, 4),
        "silence_ratio": round(noise_ratio, 4),
    },
    "recommendations": recommendations,
}

out_json.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

with out_md.open("a", encoding="utf-8") as f:
    f.write("## Metrics\n")
    for k, v in result["metrics"].items():
        f.write(f"- {k}: {v}\n")
    f.write("\n## Recommendations\n")
    for idx, rec in enumerate(recommendations, start=1):
        f.write(f"{idx}. {rec}\n")
PY

echo "" >> "$REPORT_MD"
echo "[OK] Day46 alert noise review completed" | tee -a "$REPORT_MD"
echo "[INFO] markdown: $REPORT_MD"
echo "[INFO] json: $REPORT_JSON"
