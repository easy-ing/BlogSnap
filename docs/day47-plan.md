# Day47 Plan - Incident Watcher

## Goal
- release-health/day46 신호를 기반으로 장애 징후를 감지하고 복구 런북을 자동 연계한다.

## Checklist
- [x] incident watcher 스크립트 추가
- [x] md/json incident summary 생성
- [x] incident 시 Day41 복구 시나리오 자동 실행 연계
- [x] Day47 실행 검증

## Run
```bash
./scripts/day47_incident_watcher.sh .env.example tmp/reports
```
