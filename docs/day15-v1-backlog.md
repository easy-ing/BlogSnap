# Day15 MVP Exit & V1 Backlog

## MVP 종료 기준
1. 핵심 플로우 자동화 가능
- 글 유형 선택 -> 초고 생성(2~3안) -> 선택 -> publish 까지 end-to-end 동작

2. 운영 최소 기준 충족
- health/readiness/metrics 확인 가능
- 알림 라우팅 warning/critical 분리
- CI 기본 게이트(lint/test/compile/check) 자동화

3. 회귀 방지 장치
- 핵심 통합 테스트/재시도 테스트 존재
- Day14 CI 스위트 재현 가능

## V1 우선 백로그 (우선순위 순)
1. 실제 채널 연동 고도화
- Slack/PagerDuty 실환경 연동
- 알림 dedup/silence 정책 고도화

2. 인증/권한
- 사용자 인증
- 프로젝트 접근 제어

3. 예약 발행/스케줄링
- publish 예약 시간 설정
- 예약 queue + retry 정책 강화

4. 컨텐츠 품질 개선
- 초고 평가 기준(길이/톤/키워드 반영률)
- A/B 초고 선택 추천

5. 멀티 블로그 제공자
- 티스토리/네이버 블로그 연동
- provider별 오류 처리/재시도 정책

## V1 수용 기준 (초안)
- 최소 2개 provider 지원
- 예약 발행 성공률 목표 정의
- 운영 알림 false positive 비율 목표 정의
