# Day 10 Alert Runbook

## 대상 알림
- `BlogSnapAPIHighErrorRate` (warning)
- `BlogSnapAPISlowP95` (warning)
- `BlogSnapJobsFailing` (critical)

## 1차 확인 절차
1. Alertmanager 상태 확인
   - `http://127.0.0.1:9093/#/alerts`
2. Prometheus 룰 상태 확인
   - `http://127.0.0.1:9090/rules`
3. Grafana 대시보드 확인
   - `http://127.0.0.1:3000/d/blogsnap-overview`
4. API/Worker 컨테이너 로그 확인
   - `docker compose -f docker-compose.dev.yml logs --tail=200 api worker`

## 알림별 대응 가이드
### BlogSnapAPIHighErrorRate
- 최근 배포/설정 변경 유무 확인
- API 로그에서 5xx 증가 구간과 에러 패턴 확인
- DB readiness 상태 (`GET /health/ready`) 확인

### BlogSnapAPISlowP95
- DB 연결 지연 여부 및 쿼리 병목 확인
- 워커와 API 리소스 경쟁 여부 확인
- 필요 시 worker poll/batch 값 완화 검토

### BlogSnapJobsFailing
- 실패 Job 상세 조회 (`GET /v1/jobs/{job_id}`)
- publish 모드 설정 (`WORKER_PUBLISH_MODE`)과 외부 블로그 자격증명 확인
- 재시도 누적 시 수동 실행 API로 단건 검증

## 로컬 전달 점검
```bash
./scripts/day10_alert_delivery_demo.sh
```

정상 기준:
- Alertmanager API에 synthetic alert 등록 성공
- `tmp/alert-webhook/alerts.jsonl`에 수신 이벤트 기록
