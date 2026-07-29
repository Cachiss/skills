# Diagnóstico en el host de Dokploy

Casi siempre el fallo es de **configuración de Dokploy**, no del Dockerfile. Diagnostica en el host
antes de tocar código.

## Reconocimiento rápido

```bash
APP=<nombre-app-dokploy>            # el que muestra Dokploy: <proyecto>-<hash>
C=$(docker ps -a --filter "name=$APP" --format '{{.Names}}' | head -1)

docker ps -a --filter "name=$APP" --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
git -C /etc/dokploy/compose/$APP/code log --oneline -1
docker logs --tail 60 "$C"
```

## Síntoma → causa

| Síntoma | Causa probable | Comprobación |
|---|---|---|
| `Compose file not found` | Dokploy clona otra rama | `git -C /etc/dokploy/compose/$APP/code log --oneline -1` |
| **Bad Gateway** + contenedor `healthy` | Container Port ≠ 80 en Domains | ver *Enrutado* abajo |
| **Bad Gateway** + contenedor reiniciando | la app aborta al arrancar | `docker logs $C` |
| Sale con `APP_KEY no está definida` | faltan variables en Environment | `ls -la /etc/dokploy/compose/$APP/` |
| Carga sin estilos | assets no publicados o URLs http | ver *Estilos* abajo |
| Laravel ignora las variables | falta `clear_env = no` | `docker exec $C php -r 'var_dump(env("APP_URL"));'` |
| `network dokploy-network not found` | falta la red o no es attachable | `docker network inspect dokploy-network --format '{{.Attachable}}'` |
| Sin certificado TLS | el backend estaba caído al pedirlo | `docker logs dokploy-traefik \| grep -i acme` |

## Enrutado: distinguir Traefik de la app

La prueba definitiva — desde el contenedor de Traefik hacia la IP de la app:

```bash
IP=$(docker inspect "$C" --format '{{(index .NetworkSettings.Networks "dokploy-network").IPAddress}}')
docker exec dokploy-traefik wget -q -O /dev/null -S "http://$IP:80/up"     # esperado: HTTP/1.1 200
docker exec dokploy-traefik wget -q -O /dev/null -S --timeout=5 "http://$IP:3000/up"
```

Si `:80` responde 200 y el dominio da Bad Gateway, el puerto configurado en **Domains** está mal.
Confírmalo leyendo los labels que genera Dokploy:

```bash
docker inspect "$C" --format '{{json .Config.Labels}}' | tr ',' '\n' | grep -E 'loadbalancer.server.port|routers.*rule'
```

Arreglo en la UI: **Domains → Container Port = 80**. No hace falta rebuild.

## Estilos

```bash
# ¿Se compiló el bundle de Vite?
docker exec "$C" ls public/build/assets/

# ¿Se publicaron los de Filament y sus plugins?
docker exec "$C" ls public/css/filament public/js/filament

# ¿Se sirven de verdad? 200 con text/html = 404 disfrazado
docker exec "$C" php -r '$h=get_headers("http://127.0.0.1/build/assets/app.css"); print_r($h);'

# ¿Laravel genera https?
docker exec "$C" php artisan tinker --execute='echo url("/");'
```

Si devuelve `http://`, revisa `trustProxies`, `URL::forceScheme` y `APP_URL`.

## Variables de entorno

Dokploy escribe un `.env` junto al compose cuando defines variables en la UI. Si el directorio sólo
tiene `code/`, no hay ninguna configurada:

```bash
ls -la /etc/dokploy/compose/$APP/
docker exec "$C" sh -c '[ -n "$APP_KEY" ] && echo "APP_KEY: si" || echo "APP_KEY: NO"'
docker exec "$C" sh -c 'echo "APP_URL=$APP_URL"'
```

`APP_URL` sin `https://` es un error silencioso: la app carga pero los enlaces absolutos salen mal.

## Procesos dentro del contenedor

```bash
docker exec "$C" supervisorctl -c /etc/supervisor/supervisord.conf status
docker inspect --format '{{.State.Health.Status}}' "$C"
```

Si `queue` o `scheduler` aparecen en `FATAL`, mira sus logs: casi siempre es la BD inalcanzable.

## Recursos del host

```bash
df -h /                                  # los builds de Docker llenan el disco
docker system df
docker builder prune -f                  # si falta espacio
```
