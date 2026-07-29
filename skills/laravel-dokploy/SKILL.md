---
name: laravel-dokploy
description: >
  Dockeriza un proyecto Laravel (incluido Filament/Livewire) para desplegarlo en Dokploy detrás de
  Traefik: Dockerfile multi-etapa con nginx + php-fpm + queue worker + scheduler, docker-compose sin
  puertos publicados, y contenedores opcionales de base de datos, Redis o almacenamiento. Úsalo
  cuando se pida dockerizar, containerizar o desplegar un proyecto Laravel en Dokploy, y también
  para diagnosticar despliegues rotos en Dokploy (Bad Gateway, "Compose file not found", estilos que
  no cargan, variables de entorno que Laravel no ve).
---

# Laravel → Dokploy

Dokploy despliega con `docker compose up -d --build` y enruta con **Traefik**. El contenedor no
publica puertos: Traefik lo alcanza por la red `dokploy-network`.

Las plantillas de `templates/` están probadas en producción con Laravel 12 + Filament 3. Cópialas y
adáptalas; no las reescribas desde cero.

## Paso 0 · Inspecciona antes de escribir nada

No asumas la forma del proyecto. Ejecuta:

```bash
# Versión de PHP y paquetes que condicionan extensiones
grep -E '"(php|laravel/framework)"' composer.json
grep -oE '"ext-[a-z0-9]+"' composer.lock | sort -u

# ¿Hay rutas con closures? Si las hay, route:cache REVIENTA
grep -nE '^\s*Route::[a-z]+\(.*function\s*\(' routes/*.php

# ¿Qué declara el CSS? Tailwind v4 falla si un @source no existe
grep -n '@source' resources/css/*.css

# ¿Filament? ¿Colas? ¿Scheduler?
grep -rln 'ShouldQueue' app/ | head
grep -n 'health:' bootstrap/app.php          # ruta /up para el healthcheck
grep -rn 'forceScheme\|trustProxies' app/ bootstrap/
```

Anota: versión de PHP, driver de BD, si hay closures en rutas, qué rutas declara `@source`, y si el
proyecto ya confía en proxies y fuerza HTTPS (si no lo hace, hay que añadirlo: detrás de Traefik el
CSS se bloquea por mixed-content).

## Paso 1 · Elige la variante de compose

| Situación | Variante |
|---|---|
| BD gestionada fuera (lo más común en Dokploy) | `templates/docker-compose.yml` tal cual |
| BD dentro del stack | añade el servicio de `references/compose-variants.md` |
| Archivos que deben persistir | S3 (preferido) o volumen — misma referencia |
| Redis para caché/colas/sesiones | servicio `redis` de esa misma referencia |

**Por defecto, sin BD ni almacenamiento en el compose.** Sólo añádelos si el usuario lo pide o si no
existe una BD gestionada.

## Paso 2 · Copia las plantillas y adáptalas

```
templates/Dockerfile          → ./Dockerfile
templates/dockerignore        → ./.dockerignore     (renombrar con el punto)
templates/docker-compose.yml  → ./docker-compose.yml
templates/docker/*            → ./docker/
```

Ajusta después:

1. **Versión de PHP** en la etapa `base` según `composer.json`.
2. **Extensiones**: quita `pdo_pgsql` o `pdo_mysql` según el driver real; añade lo que exija el
   proyecto (`soap`, `imagick`, …).
3. **Etapa `assets`**: por cada `@source` que apunte fuera de `resources/`, copia esa ruta a la
   etapa. Es la causa #1 de que fallen los estilos — ver `references/gotchas.md`.
4. **Entrypoint**: si el proyecto **no** usa Filament, borra las líneas `filament:*`. Si **no** hay
   closures en rutas, añade `php artisan route:cache`.
5. **Node**: alinea la versión con la que use el proyecto.

## Paso 3 · Verifica en local — no te saltes esto

Un build verde no significa que la app sirva. Comprueba las tres capas:

```bash
docker build -t app:test .

# 1) El entrypoint completo corre sin abortar
docker run --rm \
  -e APP_KEY="base64:$(openssl rand -base64 32)" -e APP_URL="https://app.test" \
  -e DB_CONNECTION=sqlite -e DB_DATABASE=":memory:" \
  -e SESSION_DRIVER=file -e CACHE_STORE=file -e QUEUE_CONNECTION=sync \
  app:test php -r 'echo "ENTRYPOINT OK\n";'

# 2) La app sirve y los ESTILOS llegan con 200 y el content-type correcto
docker run -d --name smoke -p 8099:80 \
  -e APP_KEY="base64:$(openssl rand -base64 32)" -e APP_URL="https://app.test" \
  -e DB_CONNECTION=sqlite -e DB_DATABASE=":memory:" \
  -e SESSION_DRIVER=file -e CACHE_STORE=file -e QUEUE_CONNECTION=sync app:test
sleep 12
CSS=$(docker exec smoke sh -c 'ls public/build/assets/*.css | head -1' | xargs basename)
curl -s -o /dev/null -w "up:       %{http_code}\n" http://127.0.0.1:8099/up
curl -s -o /dev/null -w "vite css: %{http_code} %{content_type} %{size_download}b\n" \
     "http://127.0.0.1:8099/build/assets/$CSS"

# 3) Supervisord levantó todo
docker exec smoke supervisorctl -c /etc/supervisor/supervisord.conf status
docker inspect --format '{{.State.Health.Status}}' smoke
docker rm -f smoke
```

Un CSS que devuelve **200 con `text/html`** es un 404 disfrazado que cayó a `index.php`.

## Paso 4 · Configura Dokploy

1. Aplicación tipo **Docker Compose** apuntando al repo.
2. **La rama importa**: Dokploy clona la rama configurada (normalmente `main`). Si el compose vive
   en otra rama, el deploy falla con `Compose file not found`. Fusiona antes de desplegar.
3. **Environment**: variables (mínimo `APP_KEY`, `APP_URL` **con `https://`**, y las de BD).
4. **Domains**: dominio + Service Name `app` + **Container Port `80`**.
   Dokploy pone **3000** por defecto y eso da **Bad Gateway**. Cámbialo siempre.
5. Primer despliegue: `RUN_MIGRATIONS=true`.

Advierte al usuario: **`APP_KEY` debe ser la que ya usa esa base de datos**. Una clave nueva vuelve
ilegibles de forma irreversible las columnas cifradas y las sesiones.

## Cuando algo falla

Diagnostica en el host por SSH antes de tocar el código: casi siempre es configuración de Dokploy,
no del Dockerfile. Síntoma → causa → comprobación en `references/troubleshooting.md`.

## Referencias

- `references/gotchas.md` — las trampas que cuestan horas: `clear_env`, cachés en runtime,
  `@source` de Tailwind v4, assets de Filament, storage efímero.
- `references/compose-variants.md` — servicios opcionales: Postgres, MySQL, Redis, MinIO, volúmenes.
- `references/troubleshooting.md` — diagnóstico por SSH en el host de Dokploy.
