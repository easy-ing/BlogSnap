# Day31 Plan - Scheduled Asset Cleanup Workflow

## 목표
- Day30 자산 정리 스크립트를 수동/정기 실행 가능한 워크플로우로 운영 경로에 편입한다.

## 완료
1. [x] GitHub Actions workflow 추가 (`workflow_dispatch` + `schedule`)
2. [x] retention_hours 입력값 지원
3. [x] CI 환경에서 DB schema 준비 후 cleanup 스크립트 실행
4. [x] Day31 문서/로드맵 반영

## 변경 파일
- [.github/workflows/day31-asset-cleanup.yml](/Users/jin/Desktop/easy_ing/BlogSnap/.github/workflows/day31-asset-cleanup.yml)
- [docs/day31-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day31-plan.md)
- [scripts/day30_asset_cleanup_run.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day30_asset_cleanup_run.sh)
