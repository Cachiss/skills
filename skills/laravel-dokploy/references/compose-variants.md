# Variantes del compose

El compose base sólo tiene `app`. Añade servicios **sólo si hacen falta**: una BD gestionada fuera
del stack casi siempre es mejor (backups, actualizaciones, y no se pierde al recrear el stack).

Ninguno de estos servicios publica puertos: se hablan por la red interna del proyecto y sólo `app`
está en `dokploy-network`.

## Regla de redes

```yaml
services:
  app:
    networks: [dokploy-network, internal]   # Traefik + servicios internos
  postgres:
    networks: [internal]                    # nunca en dokploy-network

networks:
  dokploy-network:
    external: true
  internal:
    driver: bridge
```

Poner la BD en `dokploy-network` la expone a todas las demás apps del servidor. No lo hagas.

## PostgreSQL

```yaml
  postgres:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_DATABASE:-laravel}
      POSTGRES_USER: ${DB_USERNAME:-laravel}
      POSTGRES_PASSWORD: ${DB_PASSWORD:?define DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks: [internal]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME:-laravel} -d ${DB_DATABASE:-laravel}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:
```

En `app`: `DB_CONNECTION=pgsql`, `DB_HOST=postgres`, `DB_PORT=5432`, y

```yaml
    depends_on:
      postgres:
        condition: service_healthy
```

## MySQL / MariaDB

```yaml
  mysql:
    image: mysql:8.4
    restart: unless-stopped
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    environment:
      MYSQL_DATABASE: ${DB_DATABASE:-laravel}
      MYSQL_USER: ${DB_USERNAME:-laravel}
      MYSQL_PASSWORD: ${DB_PASSWORD:?define DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:?define DB_ROOT_PASSWORD}
    volumes:
      - mysql-data:/var/lib/mysql
    networks: [internal]
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 10

volumes:
  mysql-data:
```

En `app`: `DB_CONNECTION=mysql`, `DB_HOST=mysql`, `DB_PORT=3306`.

## Redis

Merece la pena en cuanto haya más de un worker: quita presión de la BD en caché, sesiones y colas.

```yaml
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis-data:/data
    networks: [internal]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  redis-data:
```

En `app`: `REDIS_HOST=redis`, `CACHE_STORE=redis`, `SESSION_DRIVER=redis`, `QUEUE_CONNECTION=redis`.
La extensión `redis` ya viene en la imagen.

> Con `CACHE_STORE=redis`, `php artisan migrate --isolated` usa el lock de Redis. Correcto y además
> más seguro con varias réplicas.

## Almacenamiento persistente

### Opción A — S3 (recomendado)

Sin volúmenes, sin estado en el servidor, y sobrevive a recrear el stack:

```env
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=auto
AWS_BUCKET=...
AWS_URL=https://cdn.midominio.com
AWS_ENDPOINT=https://...            # R2, MinIO, Spaces…
AWS_USE_PATH_STYLE_ENDPOINT=true    # true para MinIO/R2
```

`league/flysystem-aws-s3-v3` debe estar en `composer.json`.

### Opción B — volumen en el host

Cuando no hay S3. Ata la app a ese servidor concreto:

```yaml
  app:
    volumes:
      - storage-data:/var/www/html/storage/app/public

volumes:
  storage-data:
```

Y pon `RUN_STORAGE_LINK=true` para que se cree `public/storage`.

⚠️ Monta **`storage/app/public`**, nunca `storage/` entero: taparías `storage/framework` y
`storage/logs`, que el entrypoint necesita recrear en cada arranque.

### Opción C — MinIO en el stack

Sólo si quieres S3 autoalojado. Necesita su propio dominio en Dokploy para servir los archivos:

```yaml
  minio:
    image: minio/minio:latest
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:?define MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:?define MINIO_ROOT_PASSWORD}
    volumes:
      - minio-data:/data
    networks: [internal, dokploy-network]
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 15s
      timeout: 5s
      retries: 5

volumes:
  minio-data:
```

En `app`: `AWS_ENDPOINT=http://minio:9000` y `AWS_USE_PATH_STYLE_ENDPOINT=true`.

## Separar el worker en su propio servicio

Por defecto el worker y el scheduler viven dentro de `app` (supervisord). Sepáralos cuando quieras
escalar la web sin multiplicar workers:

```yaml
  worker:
    build: {context: ., dockerfile: Dockerfile, target: runtime}
    restart: unless-stopped
    env_file: [{path: .env, required: false}]
    environment:
      RUN_QUEUE_WORKER: "true"
      RUN_SCHEDULER: "false"
      QUEUE_WORKERS: "4"
    command: ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
    networks: [internal]
```

Y en `app` pon `RUN_QUEUE_WORKER=false`. **Deja el scheduler en un solo servicio**: dos schedulers
ejecutan las tareas dos veces.
