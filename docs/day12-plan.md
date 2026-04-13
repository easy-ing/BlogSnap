# Day 12 실행 계획 (2026-04-13)

## 목표
- Alert severity(`warning`/`critical`) 별 라우팅을 분리한다.
- 운영 환경변수/시크릿 점검 스크립트와 체크리스트를 마련한다.

## 오늘 할 일
1. [x] Alertmanager receiver/route 분리
2. [x] alert-webhook 채널별 포워딩 URL 지원
3. [x] warning/critical sink 분리 및 E2E 검증 스크립트 추가
4. [x] `.env` 점검 스크립트 추가
5. [x] Day12 문서/README 업데이트

## 산출물
- [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
- [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml)
- [scripts/day12_alert_routing_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day12_alert_routing_demo.sh)
- [scripts/day12_env_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day12_env_check.sh)
- [docs/day12-secrets-checklist.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day12-secrets-checklist.md)

## 메모
- 우선순위가 높은 알림은 `ALERT_FORWARD_WEBHOOK_URL_CRITICAL`로 전송된다.
- `WARNING/CRITICAL` 전용 URL이 비어 있으면 generic URL로 폴백한다.
