# Day15 Release Checklist (MVP)

## 1) 기능/흐름 검증
- [ ] draft 생성/재생성/선택/publish 기본 플로우 정상
- [ ] worker daemon/run-batch 정상 처리
- [ ] publish idempotency 정상 동작

## 2) 품질 게이트
- [ ] `./scripts/day14_ci_suite.sh` 통과
- [ ] `./scripts/day12_env_check.sh` 결과 확인 (경고/필수값 누락 없음)
- [ ] Day 핵심 데모 스크립트 최소 1회 재실행

## 3) 관측/알림
- [ ] Prometheus target up 확인
- [ ] Alertmanager ready 확인
- [ ] Grafana dashboard 로딩 확인
- [ ] warning/critical 알림 라우팅 확인

## 4) 운영 준비
- [ ] 배포 절차 문서 최신화 확인
- [ ] 롤백 절차 리허설 여부 확인
- [ ] 장애 대응 연락/채널 확인

## 5) 릴리즈 판정
- [ ] Blocking 이슈 0건
- [ ] High 이슈 대응계획 확정
- [ ] Go / No-Go 최종 결정 기록
