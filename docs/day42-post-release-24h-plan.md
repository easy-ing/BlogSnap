# Day42 Post-Release 24h Monitoring Plan

## Window
- Start (KST):
- End (KST):
- Owner on duty:

## Monitoring Cadence
1. T+0h (배포 직후)
- `/health`, `/health/ready`, `/v1/jobs/queue-summary` 확인
- critical alert 실시간 모니터링

2. T+1h / T+2h / T+4h
- API 5xx 비율, p95 지연, publish 실패율 점검
- alert noise(중복 경보) 확인

3. T+8h / T+12h / T+24h
- 사용자 영향 이슈 집계
- 재시도 누적/큐 적체 여부 확인
- 다음날 안정화 판단

## Escalation Rules
- Critical 1건 이상: 즉시 대응 채널 호출
- Critical 3건 이상(30분): 배포 롤백 검토
- Publish 실패율 5% 이상(30분): `WORKER_PUBLISH_MODE=mock` 임시 전환 검토

## Exit Criteria
- 24시간 동안 치명 장애 없음
- 주요 SLI가 Day40 기준 이내
- 미해결 이슈는 백로그/핫픽스 계획에 등록
