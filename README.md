# natone-deploy

This repo contains Docker Compose + Nginx config for deploying:
- `natone-backend`
- `natone-nuxt`

## Directory layout on VPS
Recommended structure on the VPS:

```
/opt/natone/
  natone-deploy/
  natone-backend/
  natone-nuxt/
```

## 1) Prepare environment
Create `.env` from the example:

```
cp .env.example .env
```

Update values inside `.env`:
- `POSTGRES_PASSWORD`
- `DATABASE_URL` (same password)
- `LETSENCRYPT_EMAIL`

## 2) Start (HTTP only)
The initial config in `nginx/conf.d/natone.conf` is HTTP-only. Start the stack:

```
docker compose up -d --build
```

## 3) Get SSL certificate (Let's Encrypt)
Run certbot once:

```
docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d natone.ru -d www.natone.ru \
  --email you@example.com --agree-tos --no-eff-email
```

Then replace the nginx config with SSL-enabled one:

```
cp nginx/conf.d/natone.ssl.conf.example nginx/conf.d/natone.conf
```

Reload nginx:

```
docker compose restart nginx
```

## 4) Deploy updates
Pull backend/frontend repos and rebuild:

```
git pull
cd ../natone-backend && git pull
cd ../natone-nuxt && git pull
cd ../natone-deploy

docker compose up -d --build
```

## 5) One-command deploy
Use the script:

```
./deploy.sh
```

You can override the root path if needed:

```
ROOT_DIR=/opt/natone ./deploy.sh
```

## Local helper script
The `tools/natlog` script provides quick SSH, deploy, logs, and status commands.

Examples:

```
./tools/natlog
./tools/natlog --deploy
./tools/natlog --logs backend
```

## Backups
Create a gzip-compressed Postgres dump and keep 14 days by default.

Run manually:

```
./tools/backup.sh
```

Get latest backup path (useful for download):

```
./tools/backup.sh --latest
```

Env overrides:
- `ROOT_DIR` (default `/opt/natone`)
- `BACKUP_DIR` (default `/opt/natone/backups`)
- `RETENTION_DAYS` (default `14`)

Example cron (daily at 03:30):

```
30 3 * * * /opt/natone/natone-deploy/tools/backup.sh >> /opt/natone/backups/backup.log 2>&1
```

Download latest backup from local machine:

```
./tools/natlog --fetch-backup .
```

## Manual migrations
Run migrations on the server:

```
./tools/natlog --migrate
```

## Restore latest backup to local DB (macOS)
This will download the latest backup from the VPS and restore it to your local Postgres.

```
./tools/restore_local.sh
```

Env overrides (optional):
- `LOCAL_BACKUP_DIR` (default `/tmp/natone-backups`)
- `LOCAL_DB_NAME` (default `natone`)
- `LOCAL_DB_USER` (default `natone`)
- `LOCAL_DB_HOST` (default `localhost`)
- `LOCAL_DB_PORT` (default `5432`)

Example:

```
LOCAL_DB_USER=leonid LOCAL_DB_NAME=natone ./tools/restore_local.sh
```
