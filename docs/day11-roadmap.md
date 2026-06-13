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

## Day43 완료 (Post-Launch Stabilization Snapshot)

- 배포 직후 상태 스냅샷 자동 수집 스크립트 추가
- queue summary/metrics 헤드 포함 리포트 생성
- post-launch retrospective 템플릿 추가

## Day44 완료 (Stabilization Trend Review)

- Day42/Day43 최신 리포트 자동 집계 스크립트 추가
- 상태 스냅샷 및 권장 운영 액션 자동 요약
- 안정화 점검 가이드 문서 추가

## Day45 완료 (Release Health Bundle)

- Day42~Day44 리포트 통합 markdown/json 생성 스크립트 추가
- `release-health-latest.md/json` 최신 포인터 파일 자동 갱신
- 릴리즈 헬스 공유 가이드 문서 추가

## Day46 완료 (Alert Noise Quality Review)

- alert relay `/stats` 기반 노이즈/성공률 리뷰 스크립트 추가
- markdown/json 리포트 동시 생성 및 튜닝 추천 자동화
- alert noise 해석 가이드 문서 추가

## Day47 완료 (Incident Watcher Automation)

- release-health/day46 신호 기반 incident watcher 스크립트 추가
- incident summary markdown/json 자동 생성
- incident 감지 시 Day41 복구 시나리오 자동 실행 연계

## Day48 완료 (Deploy Approval Automation)

- release-health/day47/day42 신호 결합 배포 승인 게이트 스크립트 추가
- 승인 결과 markdown/json 및 latest 포인터 자동 생성
- 차단 사유(block reasons) 자동 기록 정책 추가

## Day49 완료 (Retro Autofill Automation)

- release-health/day48/day46 신호 기반 리트로 초안 자동 생성 스크립트 추가
- markdown/json 리트로 결과 파일 생성
- 운영 액션 아이템 자동 제안 로직 추가

## Day50 완료 (Ops Suite Orchestration)

- Day45~Day49 운영 자동화 통합 오케스트레이터 스크립트 추가
- 단계별 결과 및 리포트 경로 집계 출력
- md/json 종합 운영 스위트 리포트 생성

## Day51 완료 (Ops Status Badge)

- Day50 결과 기반 운영 상태 배지(svg) 생성 스크립트 추가
- md/json 요약 및 latest 포인터 파일 자동 갱신
- 상태 배지 운영 가이드 문서 추가

## Day52 완료 (Ops Report Manifest)

- Day45~Day51 최신 리포트 포인터를 수집하는 manifest 스크립트 추가
- manifest markdown/json 및 latest 포인터 자동 생성
- manifest 상태/누락 항목 확인 가이드 문서 추가

## Day53 완료 (Deploy Readiness Report)

- `check_deploy_ready.sh`와 운영 리포트 신호를 결합한 readiness 스크립트 추가
- Day52 manifest, Day48 approval, Day51 ops status 기반 `ready`/`blocked` 판정
- markdown/json/latest readiness 리포트 및 판단 기준 가이드 추가

## Day54 완료 (Readiness Refresh)

- Day45 release-health 상태 추출 오탐 수정
- Day45/47/48/52/53 최신 신호 재계산 스크립트 추가
- 최종 readiness decision 및 block reasons 요약 리포트 생성

## Day55 완료 (Release Lock Snapshot)

- Day53 `ready` 상태를 배포 승인용 lock snapshot으로 고정하는 스크립트 추가
- git branch/commit 및 source checksum 기록
- markdown/json/latest lock 리포트 및 운영 가이드 추가

## Day56 완료 (Release Handoff Package)

- Day55 release lock을 최신 HEAD 기준으로 재생성하는 핸드오프 스크립트 추가
- lock commit/branch 및 readiness/source checksum 재검증
- markdown/json/latest 배포 인수인계 패키지 생성

## Day57 완료 (Release Evidence Index)

- Day56 handoff를 갱신하고 배포 승인 evidence 인덱스 생성
- Day53/55/56/52/51/48/release-health 최신 리포트 수집
- handoff commit/branch와 현재 HEAD 일치 검증

## Day58 완료 (Deployment Execution Receipt)

- Day57 evidence 기반 배포 실행 receipt 생성 스크립트 추가
- dry-run/execute 모드 및 execute 확인 가드 추가
- markdown/json/latest receipt 및 운영 가이드 생성

## Day59 완료 (Post-Deploy Verification)

- Day58 deployment receipt를 최신 HEAD 기준으로 자동 갱신하는 검증 스크립트 추가
- receipt/evidence/git branch/commit 및 deploy action/target 일치성 점검
- markdown/json/latest verification 리포트 및 운영 가이드 생성
