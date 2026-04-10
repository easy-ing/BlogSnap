# Day 9 실행 계획 (2026-04-10)

## 목표
- Day8 메트릭 기반으로 알람/대시보드를 포함한 관측 스택을 완성한다.
- 운영자가 장애 징후를 빠르게 확인할 수 있도록 룰과 시각화를 제공한다.

## 오늘 할 일
1. [x] Prometheus alert rules 추가
2. [x] Alertmanager 로컬 설정/서비스 추가
3. [x] Grafana datasource + dashboard provisioning 추가
4. [x] Day9 관측 확장 스모크 테스트 추가/검증
5. [x] README/Backend README 업데이트

## 산출물
- [monitoring/rules/blogsnap-alerts.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/rules/blogsnap-alerts.yml)
- [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- [monitoring/grafana/provisioning/datasources/prometheus.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/grafana/provisioning/datasources/prometheus.yml)
- [monitoring/grafana/provisioning/dashboards/dashboards.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/grafana/provisioning/dashboards/dashboards.yml)
- [monitoring/grafana/dashboards/blogsnap-overview.json](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/grafana/dashboards/blogsnap-overview.json)
- [scripts/day9_observability_plus_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day9_observability_plus_demo.sh)

## 메모
- 로컬 검증 중심 구성
- 실제 Slack/PagerDuty 연동은 Day10+에서 비밀정보 기반으로 확장
