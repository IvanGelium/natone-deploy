#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:-/tmp/natone-backups}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-natone}"
LOCAL_DB_USER="${LOCAL_DB_USER:-natone}"
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"

mkdir -p "$LOCAL_BACKUP_DIR"

# Download latest backup from VPS
"$REPO_DIR/tools/natlog" --fetch-backup "$LOCAL_BACKUP_DIR"

LATEST_GZ="$(ls -1t "$LOCAL_BACKUP_DIR"/natone_*.sql.gz | head -n 1)"
LATEST_SQL="${LATEST_GZ%.gz}"

echo "==> Using backup: $LATEST_GZ"

gunzip -c "$LATEST_GZ" > "$LATEST_SQL"

echo "==> Restoring to local database $LOCAL_DB_NAME"

# Drop and recreate DB (requires CREATEDB privilege)
psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d postgres -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS \"$LOCAL_DB_NAME\";" \
  -c "CREATE DATABASE \"$LOCAL_DB_NAME\" OWNER \"$LOCAL_DB_USER\";"

psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$LOCAL_DB_NAME" -v ON_ERROR_STOP=1 \
  -f "$LATEST_SQL"

echo "==> Done"
