# Day12 Secrets Checklist

## 목적
- 배포 전 민감정보 누락/플레이스홀더 사용을 줄이기 위한 점검 기준

## 필수 확인
1. `.env`가 git 추적 대상이 아닌지 확인 (`.gitignore` 포함)
2. `OPENAI_API_KEY`가 플레이스홀더(`sk-...`)가 아닌지 확인
3. `DATABASE_URL`이 운영 DB로 설정되어 있는지 확인
4. `WORKER_PUBLISH_MODE=wordpress`일 경우 WordPress 계정/앱패스워드 확인
5. alert forward URL 중 최소 1개(`generic|warning|critical`) 설정 확인

## 권장 설정
- `ALERT_FORWARD_WEBHOOK_URL_WARNING`와 `ALERT_FORWARD_WEBHOOK_URL_CRITICAL`를 분리해 채널별 노이즈 제어
- 운영/개발 `.env` 분리 (`.env.prod`, `.env.dev`)
- 시크릿 회전 주기 문서화

## 자동 점검
```bash
./scripts/day12_env_check.sh
```

특정 파일 검사:
```bash
./scripts/day12_env_check.sh /path/to/.env.prod
```
