#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EXAMPLE_FILE="$ROOT_DIR/.env.example"
COMPOSE_FILE="$ROOT_DIR/docker-compose.dev.yml"

if [ ! -f "$EXAMPLE_FILE" ]; then
  echo "ERROR: .env.example 파일을 찾을 수 없습니다."
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env 파일이 없습니다. .env.example을 복사하여 필요한 값을 채워주세요."
  exit 1
fi

missing_keys=()
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
    continue
  fi
  key="${line%%=*}"
  if ! grep -qE "^${key}=" "$ENV_FILE"; then
    missing_keys+=("$key")
  fi
done < "$EXAMPLE_FILE"

if [ "${#missing_keys[@]}" -gt 0 ]; then
  echo "ERROR: .env에 필요한 환경 변수가 누락되었습니다."
  for key in "${missing_keys[@]}"; do
    echo "  - $key"
  done
  exit 1
fi

echo "✅ .env에 .env.example에 정의된 모든 키가 포함되어 있습니다."

echo "🔎 docker-compose.dev.yml 구성 검사 중..."
if command -v docker >/dev/null 2>&1; then
  docker compose -f "$COMPOSE_FILE" config >/dev/null
  echo "✅ docker-compose.dev.yml이 유효합니다."
else
  echo "WARNING: docker가 설치되어 있지 않아 docker-compose 검사만 건너뜁니다."
fi

echo "🎉 배포 준비 체크가 완료되었습니다."
