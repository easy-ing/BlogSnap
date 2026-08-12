# Day62 Plan - UAT Session Packet

## Goal
- 사용자가 직접 웹 미리보기를 테스트할 때 따라갈 수 있는 UAT 세션 패킷을 만든다.

## Checklist
- [x] Day61 preview readiness latest 자동 갱신
- [x] Day61 preview 상태와 현재 HEAD 일치성 확인
- [x] 테스트용 URL 및 API 확인 경로 정리
- [x] 로그인/프로젝트/초고 생성/재생성/선택/발행 수동 테스트 절차 작성
- [x] 이슈 기록 템플릿 작성
- [x] markdown/json/latest UAT 세션 리포트 생성

## Run
```bash
API_URL=http://127.0.0.1:8000 \
FRONTEND_URL=http://127.0.0.1:5173 \
./scripts/day62_uat_session_packet.sh tmp/reports tmp/reports
```

## Strict Mode
```bash
UAT_STRICT=yes \
API_URL=http://127.0.0.1:8000 \
FRONTEND_URL=http://127.0.0.1:5173 \
./scripts/day62_uat_session_packet.sh tmp/reports tmp/reports
```
