# Day15 Operations Handbook

## 1. 배포 절차 (로컬/운영 공통 기본형)
1. 현재 브랜치/커밋 확인
2. CI 상태 확인 (필수)
3. 환경변수/시크릿 점검
4. 서비스 기동 및 health/readiness 점검
5. smoke/test script 실행

권장 명령:
```bash
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/day14_ci_suite.sh
```

## 2. 롤백 절차
1. 문제 버전 커밋 확인
2. 직전 정상 커밋/태그 식별
3. 코드 롤백 + 컨테이너 재시작
4. health, queue, metrics 확인

점검 엔드포인트:
- `GET /health`
- `GET /health/ready`
- `GET /v1/jobs/queue-summary`
- `GET /health/metrics`

## 3. 장애 대응 절차
1. Alertmanager/Grafana에서 경보 확인
2. API/Worker 로그에서 에러 패턴 확인
3. 영향 범위 판단 (draft/publish/queue)
4. 임시 완화 조치 (재시도/모드 전환/트래픽 제한)
5. 원인 분석 및 사후 문서화

로그 확인 예시:
```bash
docker compose -f docker-compose.dev.yml logs --tail=200 api worker alertmanager
```

## 4. 책임 분리 (MVP 단계)
- 개발: 배포/코드 수정/핫픽스
- 운영: 알림 모니터링/초기 대응
- 공통: 장애 리뷰 및 재발방지 액션

## 5. 변경 관리
- PR 단위 변경 이유/영향 범위 명시
- 배포 전 체크리스트 점검 결과 첨부
- 릴리즈 후 24시간 모니터링 기록
