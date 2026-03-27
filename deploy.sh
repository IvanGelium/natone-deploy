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

echo "==> Restarting nginx to refresh upstream DNS"
docker compose restart nginx

echo "==> Health check"
for i in {1..10}; do
  if curl -fsS http://localhost/ >/dev/null && curl -fsS http://localhost/api/health >/dev/null; then
    echo "==> OK"
    break
  fi
  echo "==> Waiting for services... ($i/10)"
  sleep 2
done

echo "==> Done"
