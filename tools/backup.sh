#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/opt/natone}"
DEPLOY_DIR="$ROOT_DIR/natone-deploy"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
  echo "Missing $DEPLOY_DIR/.env" >&2
  exit 1
fi

# Load POSTGRES_PASSWORD for pg_dump (if needed)
set -a
. "$DEPLOY_DIR/.env"
set +a

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$BACKUP_DIR/natone_${TIMESTAMP}.sql.gz"

cd "$DEPLOY_DIR"

echo "==> Dumping database to $OUT_FILE"
PGPASSWORD="${POSTGRES_PASSWORD:-}" docker compose exec -T db \
  pg_dump -U postgres -d natone | gzip > "$OUT_FILE"

# Remove old backups
find "$BACKUP_DIR" -type f -name "natone_*.sql.gz" -mtime +"$RETENTION_DAYS" -print -delete

echo "==> Backup complete"
