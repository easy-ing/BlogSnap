# 배포 전 시크릿/DB 보호 체크리스트

## 이미 반영된 것
- [x] `.dockerignore` 추가 — 이전에는 `.env`(실제 API 키 포함)가 그대로 Docker 이미지에 baked-in 되고 있었음. 이미지를 어디든 push하면 키가 유출되는 상태였음.
- [x] `AUTH_SECRET_KEY` 프로덕션 가드 — `APP_ENV=production`인데 기본값(`change-me-dev-secret`)이거나 32자 미만이면 서버가 아예 기동을 거부함([backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py)). JWT 서명키가 기본값이면 누구나 유효한 토큰을 위조할 수 있어 가장 치명적인 항목.

## 배포 전 직접 확인해야 하는 것
- [ ] **DB 비밀번호**: [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml)의 `POSTGRES_PASSWORD: blogsnap`은 로컬 개발 전용입니다. 프로덕션 DB는 반드시 별도의 강한 비밀번호를 쓰고, 이 compose 파일을 그대로 배포에 쓰지 마세요.
- [ ] **DB 네트워크 접근 제한**: 프로덕션 DB는 인터넷에 직접 노출하지 말고, 앱 서버에서만 접근 가능하도록 VPC/방화벽으로 제한.
- [ ] **DB 백업**: 최소 일 1회 자동 백업 + 복구 테스트. 매니지드 DB(RDS, Supabase, Neon 등)를 쓰면 이 부분이 대부분 자동으로 해결됨 — 직접 서버에 postgres를 올리는 것보다 권장.
- [ ] **시크릿 저장 방식**: `.env` 파일을 서버에 두고 쓰는 대신, 호스팅 플랫폼의 환경변수 주입 기능(Vercel/Railway/Render/Fly.io 등) 또는 시크릿 매니저(Doppler, 1Password, AWS Secrets Manager)를 사용. 서버 디스크에 평문 시크릿 파일을 남기지 않는 게 원칙.
- [ ] **API 키 유출 시 비용 방어**: OpenAI/Gemini 콘솔에서 사용량 알림(budget alert)과 월 한도를 미리 설정. 키가 유출되면 과금이 몰릴 수 있음.
- [ ] **HTTPS 강제**: 프로덕션에서는 반드시 HTTPS. 로그인 토큰이 평문 HTTP로 오가면 탈취 위험.
- [ ] **최소 권한 DB 계정**: 앱이 쓰는 DB 유저는 필요한 스키마에만 권한을 주고, 관리자 계정과 분리.
- [ ] **`.env` 커밋 여부 재확인**: `git log --all --full-history -- .env`로 과거에 실수로 커밋된 적이 없는지 확인. 있다면 해당 키들은 이미 유출된 것으로 간주하고 전부 재발급.

## 참고
- `.env`는 [.gitignore](/Users/jin/Desktop/easy_ing/BlogSnap/.gitignore)에 이미 포함되어 있어 git에는 안 올라감. 이번에 고친 건 "git에는 안 올라가지만 Docker 이미지에는 들어가고 있던" 별개의 구멍.
