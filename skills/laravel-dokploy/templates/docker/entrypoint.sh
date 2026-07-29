#!/bin/sh
set -e

cd /var/www/html

echo "▶ Arrancando contenedor"

# ---------------------------------------------------------------------------
# 1. Estructura de escritura
#    El contenedor es efímero (sin volumen): se recrea en cada arranque.
# ---------------------------------------------------------------------------
mkdir -p \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/app/public \
    storage/app/private/livewire-tmp \
    storage/app/temp \
    storage/logs \
    storage/api-docs \
    bootstrap/cache \
    /var/lib/nginx/tmp

chown -R www-data:www-data storage bootstrap/cache public /var/lib/nginx
chmod -R ug+rwX storage bootstrap/cache

# ---------------------------------------------------------------------------
# 2. Comprobaciones mínimas de entorno
# ---------------------------------------------------------------------------
if [ -z "${APP_KEY}" ]; then
    echo "✖ APP_KEY no está definida. Genérala con 'php artisan key:generate --show'"
    echo "  y añádela a las variables de entorno en Dokploy."
    exit 1
fi

if [ -z "${APP_URL}" ]; then
    echo "⚠ APP_URL no está definida: las URLs absolutas (correos, PDFs) pueden salir mal."
fi

# ---------------------------------------------------------------------------
# 3. Cachés de Laravel
#    Se generan aquí y no en el build porque las variables de entorno las
#    inyecta Dokploy en tiempo de ejecución.
# ---------------------------------------------------------------------------
echo "▶ Limpiando cachés heredadas de la imagen"
php artisan optimize:clear >/dev/null 2>&1 || true
php artisan filament:optimize-clear >/dev/null 2>&1 || true

php artisan package:discover --ansi
php artisan config:cache
php artisan event:cache || true
# route:cache omitido: si el proyecto define rutas con closures, Laravel no puede
# serializarlas y el arranque revienta. Compruébalo con
#   grep -nE '^\s*Route::[a-z]+\(.*function\s*\(' routes/*.php
# Si no hay closures, descomenta la línea siguiente:
# php artisan route:cache

# ---------------------------------------------------------------------------
# 3b. Estilos y assets
#     Los CSS/JS de Filament y de sus plugins (forms, tables, notifications,
#     widgets, support, guava/calendar) se republican desde vendor/ en cada
#     arranque para que nunca queden desfasados respecto a composer.lock.
#     El bundle de Vite (public/build) ya viene compilado desde el build.
# ---------------------------------------------------------------------------
echo "▶ Publicando estilos y assets"
# Si el proyecto NO usa Filament, borra las líneas filament:* de este archivo.
php artisan filament:assets --ansi || echo "⚠ filament:assets falló"
php artisan vendor:publish --tag=laravel-assets --force --ansi >/dev/null 2>&1 || true

if [ ! -f public/build/manifest.json ]; then
    echo "✖ Falta public/build/manifest.json: los estilos de Vite no se compilaron."
    exit 1
fi

echo "▶ Compilando vistas y cacheando componentes"
php artisan view:cache || echo "⚠ view:cache falló; las vistas se compilarán bajo demanda"
php artisan icons:cache || true
php artisan filament:cache-components || echo "⚠ filament:cache-components falló"

# ---------------------------------------------------------------------------
# 4. Tareas opcionales de despliegue
# ---------------------------------------------------------------------------
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    echo "▶ Ejecutando migraciones"
    php artisan migrate --force --isolated || php artisan migrate --force
fi

if [ "${RUN_STORAGE_LINK}" = "true" ]; then
    echo "▶ Creando enlace public/storage"
    php artisan storage:link || true
fi

chown -R www-data:www-data storage bootstrap/cache public

echo "▶ Listo · nginx escuchando en :80"
exec "$@"
