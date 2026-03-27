#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/opt/natone}"
DEPLOY_DIR="$ROOT_DIR/natone-deploy"
BACKEND_DIR="$ROOT_DIR/natone-backend"
FRONTEND_DIR="$ROOT_DIR/natone-nuxt"

if [[ ! -d "$DEPLOY_DIR" ]]; then
  echo "Deploy dir not found: $DEPLOY_DIR" >&2
  exit 1
fi

pull_repo() {
  local dir="$1"
  local name="$2"

  if [[ -d "$dir/.git" ]]; then
    echo "==> Pulling $name"
    git -C "$dir" pull --ff-only
  else
    echo "==> Skip $name (not a git repo at $dir)"
  fi
}

pull_repo "$BACKEND_DIR" "backend"
pull_repo "$FRONTEND_DIR" "frontend"

echo "==> Rebuilding and starting containers"
cd "$DEPLOY_DIR"
docker compose up -d --build

echo "==> Done"
