# Day 3 준비: Job Retry 정책 확정

## 1) 공통 정책
- 대상 상태: `FAILED`가 아닌 `RETRYING` 상태로 전이 가능한 실패만 재시도
- 최대 재시도 횟수: 기본 3회 (`max_attempts=3`)
- 백오프 전략: 지수 백오프 + 지터
- 중복 실행 방지: `idempotency_key` 강제

백오프 수식:
- `delay_seconds = min(base * (2 ^ (attempt - 1)) + jitter, max_delay)`
- `jitter`: 0~3초 랜덤

## 2) Job 타입별 수치
### draft_generate / draft_regenerate
- base: 5초
- max_delay: 60초
- max_attempts: 3
- timeout: 45초

재시도 대상 예시:
- OpenAI 429, 500, 502, 503, 504
- 네트워크 timeout/connection reset

즉시 실패(재시도 안 함):
- 요청 검증 실패(잘못된 입력)
- 이미지 파일 없음/손상
- 인증 키 누락

### publish
- base: 10초
- max_delay: 120초
- max_attempts: 4
- timeout: 60초

재시도 대상 예시:
- WordPress 429, 500, 502, 503, 504
- 일시적 네트워크 장애

즉시 실패(재시도 안 함):
- 401/403 인증 오류
- 400 계열 요청 포맷 오류
- provider 설정 누락

## 3) 상태 전이 규칙
1. `PENDING` -> `RUNNING`
2. 처리 실패 + 재시도 가능 + attempt < max_attempts: `RETRYING`
3. 재실행 시 `RETRYING` -> `RUNNING`
4. 처리 성공: `SUCCEEDED`
5. 최종 실패: `FAILED`

## 4) 운영 가드레일
- 동일 idempotency_key로 `publish` 중복 요청 시 기존 job 반환
- `publish` 성공 후 동일 draft 재업로드는 명시적 옵션 없으면 차단
- `FAILED` 건은 관리자 재실행 endpoint에서만 수동 재큐잉 허용
