# Day 16 실행 계획 (2026-04-18)

## 목표
- 실채널 연동 경로(Slack/PagerDuty)를 운영형으로 확장한다.
- 중복 알림 노이즈를 줄이기 위해 dedup/silence 정책을 추가한다.

## 오늘 할 일
1. [x] alert-webhook에 PagerDuty Events API 전송 추가
2. [x] alert-webhook dedup/silence 윈도우 정책 추가
3. [x] Alertmanager inhibit rule 추가 (critical 발생 시 warning 억제)
4. [x] mock pagerduty sink + Day16 검증 스크립트 추가
5. [x] README/Backend README/.env.example 업데이트

## 산출물
- [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
- [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- [monitoring/mock_pagerduty/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/mock_pagerduty/server.py)
- [scripts/day16_real_channel_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day16_real_channel_demo.sh)

## 메모
- 운영환경에서는 `ALERT_PAGERDUTY_ROUTING_KEY`를 시크릿으로 관리한다.
- dedup/silence는 프로세스 메모리 기반이므로 재기동 시 상태가 초기화된다.
