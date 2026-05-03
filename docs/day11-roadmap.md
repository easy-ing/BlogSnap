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
