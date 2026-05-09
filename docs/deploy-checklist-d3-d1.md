# Deploy Checklist (D-3 ~ D-1)

## D-3 (준비/리허설)
- [ ] 배포 브랜치/커밋 고정 (`git rev-parse --short HEAD` 기록)
- [ ] 운영 환경 파일 준비 (`.env.prod`)
- [ ] 필수 키 검증 실행
  - `./scripts/day12_env_check.sh .env.prod`
- [ ] 운영 DB 접속 확인
- [ ] 마이그레이션 리허설
  - `./scripts/db_apply_migration.sh`
- [ ] 스키마 검증
  - `./scripts/db_verify_schema.sh`
- [ ] API/Worker 기동 리허설 (운영과 동일 방식)
- [ ] 기본 헬스체크
  - `curl http://<host>/health`
  - `curl http://<host>/health/ready`
- [ ] 배포/롤백 담당자 및 절차 확인

## D-2 (통합 검증)
- [ ] 로그인/인증 흐름 테스트
- [ ] 프로젝트 생성/목록 조회 테스트
- [ ] 초고 생성(2~3개) 테스트
- [ ] 초고 선택/재생성 테스트
- [ ] 발행 요청/조회 테스트
- [ ] 예약 발행/취소/재조정 테스트
- [ ] 자산 업로드/조회/삭제 테스트
- [ ] cleanup API 테스트 (`POST /v1/assets/cleanup`)
- [ ] cleanup 리포트 스크립트 테스트
  - `./scripts/day32_asset_cleanup_report.sh 24 tmp/reports`
- [ ] workflow 수동 실행 테스트 (Day32 report workflow)
- [ ] 메트릭 확인
  - `curl http://<host>/health/metrics`
- [ ] 알림 라우팅 테스트 (warning/critical)
- [ ] 장애 시나리오 테스트 (worker 재기동, DB 재연결)

## D-1 (출시 승인)
- [ ] 최종 CI 통과 확인
  - `./scripts/day14_ci_suite.sh`
- [ ] 릴리즈 후보 버전/커밋 확정
- [ ] 최종 스모크 테스트 1회
- [ ] 백업/복구 포인트 생성 확인
- [ ] 롤백 커맨드/절차 최종 확인
- [ ] 모니터링 대시보드/알림 채널 대기 상태 확인
- [ ] 배포 시간/담당자/비상 연락망 확정
- [ ] Go/No-Go 승인 기록

## 배포 직후 체크 (T+30분)
- [ ] `/health`, `/health/ready` 정상
- [ ] 최근 에러 로그 급증 없음
- [ ] queue-summary 정상
- [ ] 실제 사용자 시나리오 1건 성공
- [ ] cleanup/report workflow 상태 정상
