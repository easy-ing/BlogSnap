# Day44 Stabilization Guide

## 목적
- 배포 직후 24~48시간 동안 운영 상태를 일관된 기준으로 점검한다.

## 확인 포인트
1. Day42 Go-Live report가 최신이고 `[OK]` 상태인지
2. Day43 Post-launch snapshot이 `[OK]` 상태인지
3. Day41/Day40 리허설 리포트가 최근 실행 이력이 있는지

## 운영 규칙
- `FAILED` 문자열이 하나라도 보이면:
  1. Day41 복구 시나리오 재실행
  2. 영향 범위 확인 후 배포/게시 속도 제한 검토
  3. 이슈 로그 남기고 리트로 템플릿 업데이트
- 전부 `[OK]`이면:
  1. 정상 운영 유지
  2. 다음 배포 전 Day42 gate 다시 실행

## 실행
```bash
./scripts/day44_stabilization_trend_report.sh tmp/reports tmp/reports
```
