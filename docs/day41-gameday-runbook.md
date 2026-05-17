# Day41 Gameday Runbook

## 목적
- 장애 상황에서 30분 내 복구 가능한지 사전 리허설한다.

## 시나리오
1. DB 경로 점검
- 스키마 검증 및 readiness 응답 확인

2. Queue 경로 점검
- queue summary 확인
- publish 플로우 1회 실행으로 작업 처리 경로 확인

3. Provider 경로 점검
- Day39 dry-run 리허설로 provider 자격/흐름 점검

## 실행
```bash
# 전체 시나리오
SCENARIO=all ./scripts/day41_gameday_recovery.sh .env.example tmp/reports

# 개별 시나리오
SCENARIO=db ./scripts/day41_gameday_recovery.sh .env.example tmp/reports
SCENARIO=queue ./scripts/day41_gameday_recovery.sh .env.example tmp/reports
SCENARIO=provider ./scripts/day41_gameday_recovery.sh .env.example tmp/reports
```

## 판정 기준
- 모든 단계 `[x]` 통과
- 최종 메시지 `[OK] Day41 gameday recovery check passed`
- 리포트 파일 생성 확인
