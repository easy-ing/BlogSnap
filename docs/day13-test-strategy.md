# Day13 Test Strategy

## 범위
- API 통합 플로우:
  - draft 생성 Job 생성
  - Job 실행 후 draft 목록 확인
  - draft 선택
  - publish Job 생성/중복키(idempotency) 확인
  - publish Job 실행 후 publish 상태 확인
- Worker 재시도:
  - retryable 예외 -> `RETRYING`
  - non-retryable 예외 -> `FAILED`

## 실행 방법
```bash
./scripts/day13_test_suite.sh
```

## 설계 원칙
- 실제 DB 스키마 기준 검증 (migration 적용 후 실행)
- 회귀 가능성이 높은 경로 우선
- 실패 시 원인 파악이 쉬운 작은 테스트 단위 유지

## 다음 단계 (Day14)
- 현재 테스트 명령을 CI 파이프라인에 연결
- PR에서 자동으로 테스트 결과 확인
