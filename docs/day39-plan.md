# Day39 Plan - Provider Rehearsal

## Goal
- 워드프레스/티스토리 실계정 연동 전 리허설 단계를 표준화한다.

## Checklist
- [x] provider별 필수 키 점검 자동화
- [x] placeholder 감지(실운영 실수 방지) 추가
- [x] `dry-run`(mock 리허설) / `real-run`(실업로드) 분리
- [x] 리허설 결과 리포트 자동 생성

## Commands
```bash
# 안전 모드(권장): 설정 점검 + mock 리허설
REHEARSAL_MODE=dry-run ./scripts/day39_provider_rehearsal.sh .env.example tmp/reports

# 실연동 모드: 실키 필요 + 명시적 허용 필요
RUN_REAL_PUBLISH=yes REHEARSAL_MODE=real-run PROVIDERS=wordpress \
  ./scripts/day39_provider_rehearsal.sh .env tmp/reports
```
