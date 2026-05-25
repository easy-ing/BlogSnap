# Day48 Plan - Deploy Approval Automation

## Goal
- 배포 승인/차단 결정을 정량 신호 기반으로 자동화한다.

## Checklist
- [x] deploy approval gate 스크립트 추가
- [x] 승인 결과 md/json + latest 포인터 생성
- [x] block reason 자동 기록
- [x] Day48 실행 검증

## Run
```bash
./scripts/day48_deploy_approval_gate.sh .env.example tmp/reports
```
