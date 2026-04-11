# Day 10 실행 계획 (2026-04-11)

## 목표
- Day9 관측 스택에 실제 알림 전달 경로를 추가한다.
- 운영자가 알림 수신부터 1차 대응까지 따라갈 수 있는 런북을 제공한다.

## 오늘 할 일
1. [x] Alertmanager webhook 대상 로컬 수신 서비스 추가
2. [x] docker compose에 alert-webhook 서비스 추가 및 연결
3. [x] Day10 알림 전달 검증 스크립트 추가/검증
4. [x] 운영 런북 문서 추가
5. [x] README/Backend README 업데이트

## 산출물
- [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
- [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml)
- [scripts/day10_alert_delivery_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day10_alert_delivery_demo.sh)
- [docs/day10-alert-runbook.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day10-alert-runbook.md)

## 메모
- Day10은 로컬 환경 기준으로 webhook 전달 경로를 검증한다.
- Slack/PagerDuty 실연동은 webhook bridge 또는 비밀정보 관리 체계와 함께 Day11+에서 확장한다.
