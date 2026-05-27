# Day49 Retro Automation Guide

## 입력
- `tmp/reports/release-health-latest.json`
- `tmp/reports/day48-deploy-approval-latest.json`
- 최신 `tmp/reports/day46-alert-noise-review-*.json`

## 출력
- `tmp/reports/day49-retro-autofill-<timestamp>.md`
- `tmp/reports/day49-retro-autofill-<timestamp>.json`

## 자동 생성 항목
- 24시간 운영 요약
- 잘된 점 3개
- 아쉬운 점 3개
- 액션 아이템 3개
- 안정화 상태 YES/NO

## 실행
```bash
./scripts/day49_retro_autofill.sh tmp/reports tmp/reports
```
