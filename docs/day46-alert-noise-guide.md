# Day46 Alert Noise Guide

## 목적
- `/stats` 기반으로 alert relay 품질을 정량 점검한다.

## 주요 지표
- `forward_success_rate`
- `forward_fail_ratio`
- `silence_ratio`

## 해석 기준
- `forward_success_rate < 0.98`:
  - webhook URL, timeout, 네트워크 상태 점검
- `silence_ratio > 0.5`:
  - silence window 과대 가능성, `ALERT_SILENCE_WINDOW_*` 하향 검토
- `silence_ratio < 0.1`:
  - 중복 경보 억제가 약할 수 있음, silence window 상향 검토

## 실행
```bash
./scripts/day46_alert_noise_review.sh .env.example tmp/reports
```
