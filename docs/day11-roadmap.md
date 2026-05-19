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

## Day 14 (완료)
- CI 파이프라인 초안 구성
- lint/test/compile/check 스텝을 PR 기준으로 자동 실행
- 실패 시 디버깅 가이드 문서화

## Day 15 (완료)
- 릴리즈 준비
- 운영 문서(배포/롤백/장애대응) 통합 정리
- MVP 종료 기준 점검 및 v1 백로그 확정

## Day 16 (완료)
- 실채널 연동(Slack/PagerDuty 이벤트 경로) 보강
- dedup/silence 정책 추가
- 알림 억제(inhibit) 규칙 및 Day16 검증 스크립트 추가

## Day 17 (완료)
- 인증(로그인/토큰) 추가
- 프로젝트 단위 접근제어(RBAC 최소형) 적용
- Day17 auth/rbac 검증 스크립트 추가

## Day 18 (완료)
- 예약 발행(`publish_at`) 추가
- 예약 시간 전 수동 실행 우회 방지
- Day18 예약 발행 데모/테스트 추가

## Day 19 (완료)
- 멀티 프로바이더 발행(`wordpress`, `tistory`) 확장
- worker publish 모드 확장(`mock`/`wordpress`/`tistory`/`live`)
- Day19 멀티 프로바이더 데모/테스트 추가

## Day 20 (완료)
- 초고 품질 점수화(키워드/길이/구조/감정톤) 로직 추가
- 추천 API `GET /v1/drafts/recommend` 추가
- Day20 추천 데모/테스트 추가

## Day 21 (완료)
- 예약 발행 제어 API 추가(`schedule update`, `cancel`)
- 예약 상태 필드 확장(`schedule_status`, `scheduled_at`, `cancelled_at`)
- 취소 예약 실행 차단 가드 + Day21 데모/테스트 추가

## Day 22 (완료)
- 예약 재조정(reconcile) 루프 분리
- `POST /v1/jobs/reconcile-schedules` API 추가
- 워커 루프에 schedule reconcile 단계 추가 + Day22 데모/테스트 추가

## Day 23 (완료)
- `claim_next_job` DB 락(`FOR UPDATE SKIP LOCKED`) 적용
- `run-next/run-batch` project 스코프 실행 경로 runner로 일원화
- Day23 프로젝트 스코프 테스트 추가

## Day 24 (완료)
- Pydantic schema 설정을 `ConfigDict` 기반으로 전환
- V2 deprecation warning 노이즈 감소
- Day24 문서/검증 반영

## Day 25 (완료)
- refresh token + logout(revoke) 인증 흐름 추가
- auth 세션 테이블(`auth_sessions`) 도입
- Day25 인증 데모/테스트 추가

## Day27 완료 (Asset Upload Integration)

- `assets` 도메인 API 추가 (`POST /v1/assets/upload`, `GET /v1/assets`)
- 프론트 이미지 입력을 실제 업로드 + `image_asset_id` 전달로 연결
- asset 업로드/조회 테스트 추가

## Day28 완료 (Asset Safety Guardrails)

- 업로드 파일 타입/용량 제한 추가
- asset soft-delete API 추가 및 목록 제외 처리
- draft 생성 시 image_asset 상태 검증 강화
- 관련 테스트 보강

## Day29 완료 (Asset Purge Maintenance)

- `POST /v1/assets/cleanup` 추가 (project 단위)
- retention 지난 `DELETED` asset DB/파일 purge
- 정리 기능 테스트 추가

## Day30 완료 (Asset Cleanup Automation)

- asset purge 공통 서비스 분리
- 전체 프로젝트 일괄 정리 실행 스크립트 추가
- 서비스 레벨 테스트 추가

## Day31 완료 (Scheduled Asset Cleanup Workflow)

- Day30 cleanup 스크립트의 수동/정기 실행 workflow 추가
- retention_hours 입력 지원
- DB schema 준비 후 자동 cleanup 실행 경로 확립

## Day32 완료 (Cleanup Report Artifact)

- cleanup 결과 JSON 리포트 스크립트 추가
- GitHub Actions artifact 업로드 workflow 추가

## Day33 완료 (Cleanup Report Summary Hardening)

- cleanup 결과 Markdown 요약 리포트 추가
- workflow Step Summary 게시
- JSON + Markdown artifact 동시 업로드

## Day34 완료 (Deploy Dry Run Automation)

- 배포 핵심 게이트 자동 점검 스크립트 추가
- dry-run 결과 리포트 생성

## Day35 완료 (Release Candidate Gate)

- RC 승인용 원클릭 게이트 스크립트 추가
- dry-run + frontend build + compile 검증 통합
- RC 게이트 리포트 자동 생성

## Day36 완료 (RC Gate Machine-Readable Status)

- RC 게이트 JSON 결과파일 추가
- 단계별 통과/실패/스킵 상태 기록
- 실패 시 즉시 JSON 남기고 종료하도록 보강

## Day37 완료 (Release Decision Gate)

- Day36 RC JSON 리포트 기준 릴리즈 승인 스크립트 추가
- 리포트 최신성(MAX_AGE_HOURS) 검증으로 stale 승인 방지
- status/step 결과 기반 pass/fail 자동 판정

## Day38 완료 (Deploy Pipeline Finalization)

- dev/staging/prod 배포 변수 매트릭스 문서 추가
- GitHub Environments/Secrets 구성 가이드 추가
- 마이그레이션 check/apply 모드 지원 배포 게이트 스크립트 추가

## Day39 완료 (Provider Rehearsal)

- 워드프레스/티스토리 provider 키 점검 리허설 스크립트 추가
- dry-run/mock 리허설과 real-run(명시 승인) 모드 분리
- placeholder 감지 및 리허설 리포트 생성 추가

## Day40 완료 (Monitoring Tuning)

- API/worker/alert 전달 기준 SLI/SLO 초안 문서 추가
- alert 임계치/노이즈 튜닝 가이드 추가
- 모니터링 설정 및 silence window 자동 점검 스크립트 추가

## Day41 완료 (Recovery Gameday)

- DB/Queue/Provider 복구 시나리오 리허설 스크립트 추가
- 게임데이 런북 문서 추가
- 시나리오별 실행 및 리포트 생성 자동화

## Day42 완료 (Go/No-Go Decision Pack)

- Day38/40/41 게이트 통합 최종 승인 스크립트 추가
- Go/No-Go 회의록 템플릿 추가
- 배포 후 24시간 모니터링 계획 문서 추가
