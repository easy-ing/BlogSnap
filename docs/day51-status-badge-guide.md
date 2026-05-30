# Day51 Status Badge Guide

## 목적
- 운영 상태를 PR/문서에서 한눈에 확인할 수 있는 배지를 생성한다.

## 입력
- 최신 `day50-ops-suite-*.json`

## 출력
- `tmp/reports/day51-ops-status-<timestamp>.md`
- `tmp/reports/day51-ops-status-<timestamp>.json`
- `tmp/reports/day51-ops-status-<timestamp>.svg`
- `tmp/reports/day51-ops-status-latest.md/json/svg`

## 상태 규칙
- Day50 suite status가 `passed`이면 배지 값 `passed`
- 그 외는 배지 값 `attention`
