# Day 11 실행 계획 (2026-04-12)

## 목표
- Day10의 로컬 수신기를 외부 알림 채널(Slack Webhook 형식)로 확장한다.
- Alertmanager 알림이 실제로 포워딩되는 경로를 검증한다.

## 오늘 할 일
1. [x] alert-webhook에 외부 webhook 포워딩 기능 추가
2. [x] mock sink 서비스 추가 (로컬 검증용)
3. [x] Day11 webhook relay E2E 스크립트 추가/검증
4. [x] Day11 진행 현황 문서 업데이트
5. [x] Day11+ 남은 작업표 정리

## 산출물
- [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
- [monitoring/mock_sink/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/mock_sink/server.py)
- [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml)
- [scripts/day11_webhook_relay_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day11_webhook_relay_demo.sh)
- [docs/day11-roadmap.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day11-roadmap.md)

## 메모
- `ALERT_FORWARD_WEBHOOK_URL`가 설정되면 alert-webhook이 Slack 호환 payload를 전송한다.
- Day12+에서 인증/비밀정보 관리 및 배포 자동화로 확장한다.
