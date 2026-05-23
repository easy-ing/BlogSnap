# Day46 Plan - Alert Noise Quality Review

## Goal
- alert forwarding 품질과 노이즈 비율을 수치로 확인하고 튜닝 제안을 자동 생성한다.

## Checklist
- [x] alert stats 기반 리뷰 스크립트 추가
- [x] markdown/json 리포트 동시 생성
- [x] 노이즈/성공률 기반 추천 로직 추가
- [x] Day46 실행 검증

## Run
```bash
./scripts/day46_alert_noise_review.sh .env.example tmp/reports
```
