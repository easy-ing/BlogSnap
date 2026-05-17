# Day41 Plan - Recovery Gameday

## Goal
- 배포 전 장애 복구 리허설 루틴을 표준화한다.

## Checklist
- [x] DB/Queue/Provider 3개 복구 시나리오 정의
- [x] 시나리오 자동 실행 스크립트 추가
- [x] 게임데이 런북 문서화
- [x] Day41 실행 검증

## Run
```bash
SCENARIO=all ./scripts/day41_gameday_recovery.sh .env.example tmp/reports
```
