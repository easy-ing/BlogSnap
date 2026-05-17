# Day40 SLI/SLO Draft

## Scope
- API 응답 품질
- 워커 발행 성공 품질
- 알림 전달 신뢰성

## SLI 1: API Availability
- 정의: `1 - (5xx 응답 수 / 전체 응답 수)`
- 측정 윈도우: 5분 롤링 + 일간 집계
- 목표(SLO):
  - warning: 99.5% 미만 10분 지속
  - critical: 99.0% 미만 10분 지속

## SLI 2: API Latency (p95)
- 정의: p95 `blogsnap_http_request_duration_seconds`
- 측정 윈도우: 5분 롤링
- 목표(SLO):
  - warning: p95 > 1.0s (5분 이상)
  - critical: p95 > 2.0s (5분 이상)

## SLI 3: Publish Success Ratio
- 정의: `성공 발행 / 전체 발행 시도`
- 측정 윈도우: 30분 롤링 + 일간 집계
- 목표(SLO):
  - warning: 98% 미만
  - critical: 95% 미만

## SLI 4: Alert Forward Success
- 정의: `alerts_forward_success_total / alerts_forward_attempt_total`
- 측정 윈도우: 30분 롤링
- 목표(SLO):
  - warning: 99% 미만
  - critical: 97% 미만

## 운영 지침
- warning은 운영자 확인 후 30분 내 원인 파악
- critical은 즉시 대응 + 필요 시 `WORKER_PUBLISH_MODE=mock` 임시 전환
- 동일 이벤트 중복 알림은 silence/inhibit 정책 우선 적용
