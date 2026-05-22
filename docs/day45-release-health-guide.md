# Day45 Release Health Guide

## 목적
- 최근 운영 게이트 상태를 단일 파일로 빠르게 공유한다.

## 생성 파일
- `tmp/reports/release-health-<timestamp>.md`
- `tmp/reports/release-health-<timestamp>.json`
- `tmp/reports/release-health-latest.md`
- `tmp/reports/release-health-latest.json`

## 판정 기준
- `overall=ok`: 주요 리포트 상태에 실패 문자열 없음
- `overall=needs_attention`: 실패 문자열 감지

## 실행
```bash
./scripts/day45_release_health_bundle.sh tmp/reports tmp/reports
```
