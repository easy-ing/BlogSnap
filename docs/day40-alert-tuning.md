# Day40 Alert Tuning Guide

## 목표
- 늦지 않게 탐지하고, 과하지 않게 알린다.

## 튜닝 순서
1. `warning`/`critical` 임계치 분리 유지
2. `group_wait`, `group_interval`, `repeat_interval` 재확인
3. warning 채널 노이즈가 높으면 `for` 시간을 늘려서 튜닝
4. critical은 탐지 지연보다 오탐 억제를 우선하지 않는다

## 현재 기준점
- API 5xx 비율 경보: 5분 기준 5% 초과, 2분 지속
- API p95 지연 경보: 1초 초과, 5분 지속
- 워커 실패 경보: 10분 내 실패 1건 이상
- inhibit: `critical` 발생 시 동일 서비스 `warning` 억제

## 추천 운영 액션
- 배포 직후 24시간:
  - warning 빈도, critical 빈도, 재발 간격을 4시간 단위로 기록
  - false positive 2회 이상인 규칙은 다음 배포 전 `for` 또는 threshold 조정
- 주간 점검:
  - 알림별 MTTA/MTTR 기록
  - top noisy alert 3개 개선 과제 생성
