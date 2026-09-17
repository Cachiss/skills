# Trampas: por qué no sale el preview / el favicon

Ordenadas por frecuencia. Cada una se ha cobrado un "lo comparto y no sale el logo".

## 1. `og:image` relativa

`<meta property="og:image" content="/og-image.png">` → Facebook, WhatsApp, LinkedIn y Telegram
la ignoran. Debe ser **absoluta y https**: `https://ejemplo.com/og-image.png`.

Cómo se cuela: `asset()` con `APP_URL` mal en Laravel, falta de `metadataBase` en Next, `useSeoMeta`
con ruta relativa en Nuxt, `image_path` en Rails. Comprobación:

```bash
curl -s https://ejemplo.com | grep -o '<meta[^>]*og:image[^>]*>'
```

## 2. Caché del crawler: cambiaste la imagen y sigue saliendo la vieja

Facebook/WhatsApp, LinkedIn, Telegram y Slack **cachean la primera lectura** (horas o días). No es
un bug del sitio.

| Cliente | Cómo refrescar |
|---|---|
| Facebook / WhatsApp / Messenger / Instagram | [Sharing Debugger](https://developers.facebook.com/tools/debug/) → "Scrape Again" (WhatsApp usa la misma caché) |
| LinkedIn | [Post Inspector](https://www.linkedin.com/post-inspector/) |
| Telegram | escribir al bot `@WebpageBot` con la URL |
| X | no hay; cambiar la URL de la imagen |
| Slack / Discord / iMessage | expiran solos (~30 min – horas) |

Truco que funciona siempre: **cambia la URL de la imagen** (`og-image.png?v=2` o un nombre
nuevo). El crawler ve una imagen distinta y la descarga.

## 3. WhatsApp: imagen de más de 300 KB, o tags demasiado abajo

WhatsApp es el cliente más limitado:

- `og:image` de **más de ~300 KB** → a veces sin imagen, a veces sólo el favicon. Genera JPG
  (`--og-format jpg`) o simplifica la imagen.
- Sólo lee los **primeros ~300 KB del HTML**. Si el bloque de tags está después de CSS/JS
  inline pesado (Tailwind inline, un bundle inline, un `<svg>` sprite enorme), no lo ve.
  Los tags van **al principio de `<head>`**. `check-meta.sh` reporta el byte donde empiezan.
- Requiere `https`.

## 4. og-image con fondo transparente

Discord, Telegram y X en modo oscuro pintan negro lo transparente; un logo oscuro desaparece.
Facebook lo pinta blanco: un logo blanco desaparece. **La og-image siempre lleva fondo opaco.**
`generate-icons.sh` ya lo hace (`--og-bg`).

## 5. La app devuelve 200 con HTML para `/favicon.ico` o `/og-image.png`

SPA con catch-all, Laravel con `Route::fallback`, Next con `rewrites`: la ruta no existe como
archivo, cae al `index.html` y responde `200 text/html`. El navegador muestra favicon roto; el
crawler descarta la imagen. `check-meta.sh` lo detecta como "404 disfrazado".

Causa habitual: el archivo está en `src/`, `resources/` o `app/assets` y el bundler lo hasheó.
Va en `public/` (o el equivalente que se sirve sin tocar).

## 6. Staging protegido, WAF o bot-fight bloqueando al crawler

Si la URL pide auth básica, está detrás de Vercel Deployment Protection, Cloudflare Access, un
"Under Attack Mode" o un WAF que bloquea user-agents → el crawler recibe 401/403/página de
challenge y no hay preview. Compruébalo como lo hace el script:

```bash
curl -sI -A "facebookexternalhit/1.1" https://ejemplo.com | head -1
```

User-agents a permitir: `facebookexternalhit`, `WhatsApp`, `Twitterbot`, `LinkedInBot`,
`TelegramBot`, `Slackbot-LinkExpanding`, `Discordbot`. En Cloudflare: regla WAF "Skip" para
"Known Bots" o para esos UA.

## 7. Redirección http→https o www→apex: los tags están en la URL equivocada

El crawler sigue la redirección y lee la URL final. Si `og:url` apunta a la inicial, algunos
clientes vuelven a pedir ésa y cachean el resultado a medias. `og:url` = URL canónica final,
siempre.

## 8. `apple-touch-icon` con transparencia o sin margen

iOS **no soporta transparencia**: la pinta de negro. Y aplica su propia máscara redondeada, así
que un logo a sangre se recorta. 180×180, fondo opaco, ~12 % de margen. El script lo genera así.

## 9. Icono maskable sin zona segura

Android recorta los iconos `purpose: "maskable"` a círculo/squircle. Sólo es seguro el **círculo
interior del 80 %**; un logo cuadrado que llega al borde pierde las esquinas. Por eso
`icon-maskable-512.png` lleva 20 % de margen y fondo opaco, y `icon-512.png` (sin margen) se
declara sin `purpose` (= `any`). No pongas `"purpose": "any maskable"` en un mismo icono: uno de
los dos usos sale mal.

## 10. Safari y el favicon SVG

Safari no usa `favicon.svg` de forma fiable; cae a `favicon.ico`. Por eso el `.ico` no es
opcional aunque tengas SVG. El `sizes="32x32"` en el `<link>` del `.ico` es para que Chrome/Firefox
prefieran el SVG cuando exista.

## 11. El favicon nuevo no aparece (caché del navegador)

Los navegadores cachean el favicon con ganas. Hard refresh no basta a veces: abre en incógnito,
o cambia la URL (`/favicon.ico?v=2`). Con Chrome, `chrome://favicon/` no ayuda; lo que funciona
es borrar datos del sitio o versionar.

## 12. Next.js: `metadataBase` ausente

Síntoma: en local se ve bien (Next asume `http://localhost:3000`), en producción `og:image` apunta
a localhost o sale relativa. El build sólo avisa:
`metadataBase property in metadata export is not set`. Ponlo siempre, leyendo la URL de env.

## 13. X no muestra tarjeta grande

Falta `twitter:card = summary_large_image`. Sin él, X muestra la tarjeta pequeña (o ninguna si
no hay `twitter:*`). El resto lo toma de `og:*`. Nota: el Card Validator de X ya no muestra
preview desde 2022; para verlo, redacta un post sin publicar.

## 14. `og:image` servida con `Content-Disposition: attachment` o content-type raro

S3/R2/Supabase Storage con metadata mal puesta: la imagen se sirve como descarga o como
`application/octet-stream`. El crawler la descarta. Debe ser `image/png` o `image/jpeg` inline.

## 15. Mismo preview para todas las rutas (SPA)

Los crawlers no ejecutan JavaScript. En una SPA, `react-helmet` / `vue-meta` / `useHead` en
cliente no sirven para el preview: el crawler ve el `index.html` estático. Si hace falta preview
por ruta, hay que renderizar en servidor (Next/Nuxt/Astro SSR) o prerenderizar esas rutas.
