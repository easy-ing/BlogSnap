# Day47 Incident Response Guide

## 감지 소스
- `release-health-latest.json` 의 `overall`
- `day46-alert-noise-review-*.json` 의
  - `forward_success_rate`
  - `forward_fail_ratio`

## 감지 규칙
- `overall != ok` 이면 incident
- `forward_success_rate < 0.98` 이면 incident
- `forward_fail_ratio > 0.05` 이면 incident

## 자동 대응
- incident 감지 시:
  - `SCENARIO=all ./scripts/day41_gameday_recovery.sh` 자동 실행
- incident 미감지 시:
  - 요약 리포트만 남기고 종료

## 출력 파일
- `tmp/reports/day47-incident-summary-<timestamp>.md`
- `tmp/reports/day47-incident-summary-<timestamp>.json`
