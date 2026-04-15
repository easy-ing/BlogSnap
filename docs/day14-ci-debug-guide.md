# Day14 CI Debug Guide

## 실행 항목
CI는 아래 순서로 실행된다.
1. dependency install
2. DB schema reset + migration apply
3. lint (`ruff`, critical rules)
4. tests (`pytest`)
5. compile check (`compileall`)
6. env check (`day12_env_check.sh`)

## 로컬 재현
```bash
docker compose -f docker-compose.dev.yml up -d postgres
export DATABASE_URL=postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap
./scripts/day14_ci_suite.sh
```

## 자주 발생하는 실패 원인
1. DB 연결 실패
- postgres 컨테이너가 올라오지 않았거나 포트 충돌

2. migration 적용 실패
- DB schema/type 충돌
- 오래된 컨테이너 데이터 잔존

3. pytest 실패
- 회귀 버그 또는 테스트 픽스처 데이터 정리 누락

4. env check warning/실패
- `.env.example` 키 누락
- placeholder 값/웹훅 URL 설정 누락

## 빠른 점검 커맨드
```bash
docker ps
docker compose -f docker-compose.dev.yml logs --tail=100 postgres
PYTHONPATH=. python3 -m pytest -q tests -k flow
python3 -m ruff check --select E9,F63,F7,F82 .
```
