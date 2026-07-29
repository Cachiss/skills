# Trampas que cuestan horas

Cada una de estas se cobró un despliegue roto. Están ordenadas por frecuencia.

## 1. Dokploy enruta al puerto 3000 por defecto → Bad Gateway

Al crear un dominio, Dokploy rellena **Container Port = 3000** (pensado para Node). La imagen de
Laravel escucha en **80**. Traefik encuentra el router, no puede conectar, y devuelve `Bad Gateway`.

El contenedor aparece `Up (healthy)` — por eso engaña: el problema es de enrutado, no de app.

Comprobación desde el propio Traefik:

```bash
IP=$(docker inspect <contenedor> --format '{{(index .NetworkSettings.Networks "dokploy-network").IPAddress}}')
docker exec dokploy-traefik wget -qO- "http://$IP:80/up"    # debe responder
docker inspect <contenedor> --format '{{json .Config.Labels}}' | grep loadbalancer.server.port
```

Arreglo: **Domains → Container Port = 80**. No requiere rebuild.

## 2. Dokploy clona la rama configurada → "Compose file not found"

Si el `docker-compose.yml` está en una rama que no es la que Dokploy despliega, el clon no lo
contiene. Verifica siempre en el host:

```bash
git -C /etc/dokploy/compose/<app>/code log --oneline -1
git -C /etc/dokploy/compose/<app>/code rev-parse --abbrev-ref HEAD
```

## 3. `clear_env = no` en el pool de php-fpm

php-fpm **limpia el entorno por defecto**. Sin esta línea, las variables que Dokploy inyecta en el
contenedor no llegan a PHP y Laravel arranca con los defaults de `config/*.php`. El síntoma es
desconcertante: `docker exec ... env` muestra la variable, pero la app no la ve.

## 4. Las cachés de Laravel se generan en RUNTIME, no en el build

En el build no existen las variables de entorno: las inyecta Dokploy al arrancar. Un
`config:cache` en el Dockerfile congela los valores por defecto y la app queda apuntando a la BD
equivocada. Va todo en el entrypoint.

## 5. `route:cache` revienta con closures

`Route::get('/', function () { ... })` no es serializable. Si `routes/web.php` o `routes/api.php`
definen closures, `route:cache` falla y tumba el arranque. Detecta antes:

```bash
grep -nE '^\s*Route::[a-z]+\(.*function\s*\(' routes/*.php
```

Sin closures, añade `route:cache` al entrypoint: es una mejora real de rendimiento.

## 6. Tailwind v4: los `@source` que apuntan fuera de `resources/`

El `app.css` de Laravel 12 trae por defecto:

```css
@source '../../vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php';
@source '../../storage/framework/views/*.php';
```

La etapa `assets` sólo copia `resources/`, así que esas rutas no existen y **Tailwind aborta el
build**. Hay que copiarlas explícitamente:

```dockerfile
RUN mkdir -p storage/framework/views
COPY --from=vendor \
     /var/www/html/vendor/laravel/framework/src/Illuminate/Pagination \
     ./vendor/laravel/framework/src/Illuminate/Pagination
```

Regla: por cada `@source` fuera de `resources/`, o copias la ruta o creas el directorio.

## 7. Los assets de Filament se publican en cada arranque

`php artisan filament:assets` copia a `public/` los CSS/JS de Filament **y de todos sus plugins**
(forms, tables, notifications, widgets, support, y terceros como `guava/calendar`). Aunque estén
commiteados en `public/`, se desfasan cuando `composer.lock` cambia.

Va en el entrypoint, no en el build. Acompáñalo de:

- `vendor:publish --tag=laravel-assets --force` — assets de paquetes Laravel normales
- `icons:cache` — manifiesto de blade-icons
- `filament:cache-components` — caché de componentes del panel

## 8. `APP_URL` sin esquema

`APP_URL=midominio.com` genera URLs absolutas rotas en correos, PDFs y enlaces firmados. Tiene que
llevar `https://`.

## 9. HTTPS detrás de Traefik

Traefik termina TLS y habla HTTP con el contenedor. Si Laravel no lo sabe, genera URLs `http://`
y el navegador bloquea el CSS por mixed-content. Hacen falta las dos piezas:

- `$middleware->trustProxies(at: '*')` en `bootstrap/app.php`
- `URL::forceScheme('https')` en producción, o `APP_URL` con https y `TrustProxies` bien puesto

En nginx, pasar la cabecera al FPM:

```nginx
map $http_x_forwarded_proto $fastcgi_https { default ""; https on; }
# ...
fastcgi_param HTTPS $fastcgi_https if_not_empty;
```

Nota: `$https` **no** es una variable de nginx; hay que construirla con `map`.

## 10. `storage/` es efímero

Sin volumen, todo lo escrito en `storage/` desaparece en cada redeploy. Las subidas temporales de
Livewire funcionan igual (viven lo que dura la petición), pero lo que deba persistir necesita S3
(`league/flysystem-aws-s3-v3`) o un volumen declarado.

## 11. `APP_KEY` no se regenera nunca

Si la base de datos ya tiene columnas cifradas o sesiones activas, una `APP_KEY` nueva las vuelve
ilegibles **de forma irreversible**. Reutiliza siempre la existente.

## 12. Detalles menores que también muerden

- `opcache.validate_timestamps=0` es correcto en imágenes inmutables, pero rompe cualquier flujo que
  reescriba PHP en caliente.
- El orden de `php-fpm.d/*.conf` es alfabético: nombra tu pool `zzz-app.conf` para que gane a
  `zz-docker.conf` de la imagen oficial.
- Un comentario dentro de una continuación de línea (`\`) en `ENV` es frágil: parte el `ENV` en
  varios.
- `dokploy-network` es overlay de swarm; debe tener `attachable=true` para que un compose normal
  pueda unirse. Compruébalo con
  `docker network inspect dokploy-network --format '{{.Attachable}}'`.
