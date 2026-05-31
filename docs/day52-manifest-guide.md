# Day52 Manifest Guide

## 목적
- Day45~Day51 운영 리포트의 최신 파일 경로를 한 번에 조회한다.

## 출력 파일
- `tmp/reports/day52-ops-manifest-<timestamp>.json`
- `tmp/reports/day52-ops-manifest-<timestamp>.md`
- `tmp/reports/day52-ops-manifest-latest.json`
- `tmp/reports/day52-ops-manifest-latest.md`

## 상태값
- `ok`: 필수 리포트 포인터가 모두 존재
- `partial`: 일부 포인터 누락 (`missing` 배열 확인)

## 실행
```bash
./scripts/day52_ops_report_manifest.sh tmp/reports tmp/reports
```
