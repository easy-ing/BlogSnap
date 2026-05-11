# Day36 Plan - RC Gate Machine-Readable Status

## 목표
- RC 게이트 결과를 사람이 읽는 Markdown뿐 아니라 자동 판정 가능한 JSON으로 함께 남긴다.

## 완료
1. [x] `day35_release_candidate_gate.sh`에 JSON 상태파일 생성 추가
2. [x] 단계별 결과(`passed/failed/skipped`)를 JSON `steps` 배열로 기록
3. [x] 실패 시 즉시 JSON 기록 후 종료하도록 보강
4. [x] Day36 문서/로드맵 반영

## 변경 파일
- [scripts/day35_release_candidate_gate.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day35_release_candidate_gate.sh)
- [docs/day36-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day36-plan.md)
