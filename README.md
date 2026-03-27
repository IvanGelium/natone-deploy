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
