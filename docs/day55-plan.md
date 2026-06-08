# Day55 Plan - Release Lock Snapshot

## Goal
- `ready` 상태의 deploy readiness를 배포 승인용 lock snapshot으로 고정한다.

## Checklist
- [x] Day53 readiness latest 입력 확인
- [x] git branch/commit 기록
- [x] readiness 및 source 파일 checksum 기록
- [x] markdown/json/latest lock snapshot 생성
- [x] readiness가 `ready`가 아니면 lock 생성 실패 처리

## Run
```bash
./scripts/day55_release_lock_snapshot.sh tmp/reports tmp/reports
```
