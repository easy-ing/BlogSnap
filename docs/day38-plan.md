# Day38 Plan - Deploy Pipeline Finalization

## Goal
- 배포 전 체크를 재현 가능한 단일 파이프라인 게이트로 통합한다.

## Checklist
- [x] 배포 환경(dev/staging/prod) 변수 매트릭스 문서화
- [x] GitHub Environments/Secrets 운영 가이드 작성
- [x] 마이그레이션 체크/적용 모드가 있는 배포 게이트 스크립트 추가
- [x] Day38 스크립트 실행 검증

## Run
```bash
MIGRATION_MODE=check ./scripts/day38_deploy_pipeline_gate.sh .env.example tmp/reports
```
