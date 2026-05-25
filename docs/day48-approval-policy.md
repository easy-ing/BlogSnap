# Day48 Deploy Approval Policy

## 입력 신호
- `release-health-latest.json`
- 최신 `day47-incident-summary-*.json`
- 최신 `day42-go-live-*.md` 상태 라인

## 승인 규칙
- 아래 조건 모두 만족 시 `approved`
  1. release health overall = `ok`
  2. incident_detected = `false`
  3. day42 상태 라인에 실패 신호 없음

## 차단 규칙
- 위 조건 중 하나라도 위반 시 `blocked`
- 차단 사유는 `block_reasons`로 기록

## 출력 파일
- `tmp/reports/day48-deploy-approval-<timestamp>.md`
- `tmp/reports/day48-deploy-approval-<timestamp>.json`
- `tmp/reports/day48-deploy-approval-latest.md`
- `tmp/reports/day48-deploy-approval-latest.json`
