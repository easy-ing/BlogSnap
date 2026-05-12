# Day37 Plan - Release Decision Gate

## Goal
- Day36에서 생성한 RC gate JSON 결과를 기반으로 릴리즈 가능 여부를 자동 판정한다.

## Checklist
- [x] 최신 RC JSON 리포트 자동 탐색
- [x] 리포트 최신성(stale) 검증 (`MAX_AGE_HOURS`)
- [x] `status=passed` 및 단계별 실패 여부 검증
- [x] 통과/실패 시 표준 출력 메시지로 CI 연동 가능하게 구성

## Run
```bash
./scripts/day37_release_decision_gate.sh tmp/reports
```

## Notes
- 기본 최신성 기준은 24시간이며, `MAX_AGE_HOURS`로 조정 가능.
