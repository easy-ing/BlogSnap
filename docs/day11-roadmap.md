# Day11+ 남은 작업표

## Day 11 (완료)
- Alertmanager 알림을 외부 웹훅(Slack 형식)으로 relay
- 로컬 mock sink 기반 E2E 검증 스크립트 구성

## Day 12 (완료)
- 비밀정보 관리 체계 정리
- `.env` 기반 민감값 로딩 검증 스크립트 및 운영 체크리스트 작성
- Alert routing 수준별 분리 (`warning`/`critical`)

## Day 13 (완료)
- API/Worker 테스트 보강
- 핵심 플로우(초고 생성, 선택, 발행, 재시도) 통합 테스트 추가
- 데모 스크립트 자동 검증 단계화

## Day 14 (예정)
- CI 파이프라인 초안 구성
- lint/test/compile/check 스텝을 PR 기준으로 자동 실행
- 실패 시 디버깅 가이드 문서화

## Day 15 (예정)
- 릴리즈 준비
- 운영 문서(배포/롤백/장애대응) 통합 정리
- MVP 종료 기준 점검 및 v1 백로그 확정
