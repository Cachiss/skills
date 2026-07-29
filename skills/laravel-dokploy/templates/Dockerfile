# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Laravel → Dokploy
# Imagen única: nginx + php-fpm + queue worker + scheduler (supervisord).
# Por defecto no incluye base de datos ni almacenamiento.
#
# AJUSTA ANTES DE USAR:
#   1. La versión de PHP de abajo, según composer.json.
#   2. Las extensiones: quita el pdo_* que no uses, añade lo que exija el proyecto.
#   3. La etapa `assets`: copia cada ruta que declare un @source fuera de resources/.
#   4. La versión de Node.
# ---------------------------------------------------------------------------

# ============================ 1. Base PHP ==================================
FROM php:8.3-fpm-alpine AS base

# Instalador oficial de extensiones (resuelve las libs de Alpine por nosotros)
COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
        bcmath \
        exif \
        gd \
        intl \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        redis \
        sockets \
        zip \
    && apk add --no-cache nginx supervisor tzdata \
    && rm -rf /var/cache/apk/*

WORKDIR /var/www/html


# ====================== 2. Dependencias de Composer ========================
FROM base AS vendor

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1

# Primero sólo los manifiestos para aprovechar la caché de capas de Docker
COPY composer.json composer.lock ./

RUN composer install \
        --no-dev \
        --no-scripts \
        --no-autoloader \
        --prefer-dist \
        --no-progress

# Ahora el código, y con él el autoloader optimizado
COPY . .

RUN composer dump-autoload --no-dev --optimize


# ========================= 3. Assets con Vite ==============================
FROM node:22-alpine AS assets

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY vite.config.js ./
COPY resources ./resources

# Tailwind v4 aborta el build si un @source apunta a una ruta que no existe.
# El app.css por defecto de Laravel 12 declara estas dos. Añade las que falten
# según `grep -n '@source' resources/css/*.css`.
RUN mkdir -p storage/framework/views
COPY --from=vendor \
     /var/www/html/vendor/laravel/framework/src/Illuminate/Pagination \
     ./vendor/laravel/framework/src/Illuminate/Pagination

RUN npm run build


# ============================ 4. Runtime ===================================
FROM base AS runtime

ENV APP_ENV=production \
    APP_DEBUG=false

# Procesos opcionales dentro del contenedor
ENV RUN_QUEUE_WORKER=true \
    RUN_SCHEDULER=true \
    QUEUE_WORKERS=1

# Tareas de arranque (desactivadas por defecto: actívalas en Dokploy)
ENV RUN_MIGRATIONS=false \
    RUN_STORAGE_LINK=false

# Configuración de servicios
COPY docker/php.ini            /usr/local/etc/php/conf.d/zz-app.ini
COPY docker/php-fpm-pool.conf  /usr/local/etc/php-fpm.d/zzz-app.conf
COPY docker/nginx.conf         /etc/nginx/nginx.conf
COPY docker/supervisord.conf   /etc/supervisor/supervisord.conf
COPY docker/entrypoint.sh      /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Código de la aplicación
COPY --chown=www-data:www-data . .
COPY --from=vendor --chown=www-data:www-data /var/www/html/vendor ./vendor
COPY --from=assets --chown=www-data:www-data /app/public/build ./public/build

# Estructura de escritura. Ojo: es efímera, no hay volumen montado.
RUN mkdir -p \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/framework/testing \
        storage/app/public \
        storage/app/private \
        storage/app/temp \
        storage/logs \
        storage/api-docs \
        bootstrap/cache \
        /var/lib/nginx/tmp \
        /var/log/supervisor \
    && chown -R www-data:www-data storage bootstrap/cache public /var/lib/nginx \
    && chmod -R ug+rwX storage bootstrap/cache

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD php -r '$c=@file_get_contents("http://127.0.0.1/up"); exit($c===false?1:0);'

ENTRYPOINT ["entrypoint"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
