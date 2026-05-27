#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day49-retro-autofill-$TS.md"
OUT_JSON="$OUT_DIR/day49-retro-autofill-$TS.json"

RELEASE_HEALTH_JSON="$REPORT_DIR/release-health-latest.json"
APPROVAL_JSON="$REPORT_DIR/day48-deploy-approval-latest.json"
NOISE_JSON="$(ls -1 "$REPORT_DIR"/day46-alert-noise-review-*.json 2>/dev/null | sort | tail -n1 || true)"

if [[ ! -f "$RELEASE_HEALTH_JSON" ]]; then
  echo "[ERROR] missing release health json: $RELEASE_HEALTH_JSON"
  exit 1
fi
if [[ ! -f "$APPROVAL_JSON" ]]; then
  echo "[ERROR] missing approval json: $APPROVAL_JSON"
  exit 1
fi
if [[ -z "$NOISE_JSON" || ! -f "$NOISE_JSON" ]]; then
  echo "[ERROR] missing day46 noise json"
  exit 1
fi

python3 - <<'PY' "$RELEASE_HEALTH_JSON" "$APPROVAL_JSON" "$NOISE_JSON" "$OUT_JSON" "$OUT_MD"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

release_health = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
approval = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
noise = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
out_json = Path(sys.argv[4])
out_md = Path(sys.argv[5])

overall = release_health.get("overall", "unknown")
decision = approval.get("decision", "unknown")
block_reasons = approval.get("block_reasons", []) or []

metrics = noise.get("metrics", {})
forward_success_rate = float(metrics.get("forward_success_rate", 1.0))
forward_fail_ratio = float(metrics.get("forward_fail_ratio", 0.0))
silence_ratio = float(metrics.get("silence_ratio", 0.0))

now_kst = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d")

good_points = []
improvements = []
actions = []

if forward_success_rate >= 0.98:
    good_points.append("Alert forward 성공률이 목표 이상으로 유지됨")
else:
    improvements.append("Alert forward 성공률이 목표 미만")
    actions.append("웹훅 라우팅/타임아웃 설정 재점검 (Owner: Ops, Due: +2d)")

if forward_fail_ratio <= 0.05:
    good_points.append("Forward 실패율이 허용 범위 이내")
else:
    improvements.append("Forward 실패율이 허용 범위 초과")
    actions.append("warning/critical 채널별 웹훅 URL 유효성 점검 (Owner: Dev, Due: +1d)")

if silence_ratio < 0.1:
    improvements.append("Silence 비율이 낮아 중복 경보 가능성 존재")
    actions.append("ALERT_SILENCE_WINDOW_* 상향 실험 (Owner: Ops, Due: +3d)")
elif silence_ratio > 0.5:
    improvements.append("Silence 비율이 높아 경보 누락 위험 가능성")
    actions.append("ALERT_SILENCE_WINDOW_* 하향 실험 (Owner: Ops, Due: +3d)")
else:
    good_points.append("Silence 비율이 적정 범위")

if overall == "ok" and decision == "approved":
    stability = "YES"
    next_condition = "현재 기준 유지, 다음 배포 전 Day48 gate 재실행"
else:
    stability = "NO"
    if block_reasons:
        improvements.extend([f"배포 승인 차단 사유: {r}" for r in block_reasons])
    actions.append("차단 사유 해소 후 Day45~Day48 재실행 (Owner: Release Manager, Due: +1d)")
    next_condition = "block_reasons 해소 및 Day48 decision=approved 확인"

while len(good_points) < 3:
    good_points.append("운영 데이터 축적 중")
while len(improvements) < 3:
    improvements.append("추가 관찰 필요")
while len(actions) < 3:
    actions.append("추가 액션 정의 필요 (Owner/TBD)")

summary = {
    "status": "ok",
    "date_kst": now_kst,
    "signals": {
        "release_health_overall": overall,
        "deploy_approval_decision": decision,
        "forward_success_rate": round(forward_success_rate, 4),
        "forward_fail_ratio": round(forward_fail_ratio, 4),
        "silence_ratio": round(silence_ratio, 4),
    },
    "good_points": good_points[:3],
    "improvements": improvements[:3],
    "action_items": actions[:3],
    "stability": stability,
    "next_release_condition": next_condition,
}

out_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

md = []
md.append("# Day49 Retro Autofill")
md.append("")
md.append("## 1. 기본 정보")
md.append(f"- Date (KST): {now_kst}")
md.append("- Release commit/tag: (fill manually)")
md.append("- Owner: (fill manually)")
md.append("")
md.append("## 2. 24시간 운영 요약")
md.append(
    f"- 주요 지표 상태: release_health={overall}, deploy_approval={decision}, "
    f"forward_success_rate={forward_success_rate:.4f}, forward_fail_ratio={forward_fail_ratio:.4f}, silence_ratio={silence_ratio:.4f}"
)
md.append(f"- 장애/경보 발생 건수: incident watcher block reasons {len(block_reasons)}건")
md.append("- 사용자 영향: (fill manually)")
md.append("")
md.append("## 3. 잘된 점")
for i, item in enumerate(good_points[:3], 1):
    md.append(f"{i}. {item}")
md.append("")
md.append("## 4. 아쉬운 점")
for i, item in enumerate(improvements[:3], 1):
    md.append(f"{i}. {item}")
md.append("")
md.append("## 5. 액션 아이템")
for i, item in enumerate(actions[:3], 1):
    md.append(f"{i}. {item}")
md.append("")
md.append("## 6. 최종 판단")
md.append(f"- 안정화 상태: {stability}")
md.append(f"- 다음 배포 전 필수 조건: {next_condition}")
md.append("")
md.append("[OK] Day49 retro autofill completed")

out_md.write_text("\n".join(md), encoding="utf-8")
PY

echo "[OK] Day49 retro autofill completed"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
