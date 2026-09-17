---
name: dev-basics
description: >
  Básicos que todo proyecto web nuevo debe tener antes de entregarse, y que se revisan al tocar un
  formulario o el layout de uno existente: (1) pedir el logo al usuario y ponerlo como favicon
  (ico, svg, apple-touch-icon, manifest), metatags y Open Graph + Twitter Card con og-image para
  que el logo salga al compartir el link por WhatsApp, X, LinkedIn, Slack, Telegram o Discord;
  (2) validar teléfonos con libphonenumber, limpiar los formatos viejos de México (+52 1, 044, 01)
  y guardarlos en E.164; (3) poner el ojo de mostrar/ocultar en TODO input de contraseña. Úsalo al
  arrancar un proyecto, cuando se pida "pon el logo", "favicon", "metatags", "que se vea la imagen
  al compartir", "valida el teléfono", "campo de teléfono/celular/WhatsApp", "ojito en la
  contraseña", "mostrar/ocultar contraseña", o para diagnosticar por qué un link no muestra
  preview. Incluye scripts (generar iconos desde el logo, verificar una URL como el crawler de
  WhatsApp) y plantillas para HTML, Laravel/Filament, Next.js, Nuxt, React y Vue.
---

# Básicos de un proyecto web

Tres cosas que un proyecto **no entrega sin**, y que se revisan también en uno existente cuando se
toca el layout o un formulario:

1. **Identidad**: logo como favicon, metatags y preview al compartir el link.
2. **Teléfonos** validados y guardados en E.164.
3. **Ojo de mostrar/ocultar** en todo input de contraseña.

Al arrancar un proyecto se hacen las tres. En uno existente, la que toque: si aparece un campo de
teléfono, la 2; si aparece un `type="password"`, la 3.

## 1 · Identidad: favicon, metatags y preview al compartir

Es lo primero que ve el cliente cuando manda la URL por WhatsApp, y lo primero que falta.

### Paso 0 · Pide el logo y los datos — no los inventes

Busca antes en el repo:

```bash
find . -type f \( -iname '*logo*' -o -iname 'favicon*' -o -iname 'og-image*' -o -iname 'apple-touch*' \) \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/.git/*'
grep -rn 'og:image\|rel="icon"\|apple-touch-icon' --include='*.html' --include='*.blade.php' \
  --include='*.tsx' --include='*.vue' --include='*.astro' . 2>/dev/null | grep -v node_modules | head
```

Si **no hay logo**, pídeselo al usuario y para ahí. No uses un placeholder, no generes un logo, no
pongas una letra en un cuadrado "mientras tanto". Pide, en un solo mensaje:

1. **Logo**: SVG (ideal) o PNG con fondo transparente de ≥ 1024 px. Si sólo hay JPG o un PNG
   pequeño, sirve para empezar pero avísale de que los iconos grandes saldrán borrosos.
2. **Nombre** del proyecto y **tagline** (≤ 60 caracteres).
3. **Descripción** de una frase (≤ 160 caracteres): es lo que sale bajo el título al compartir.
4. **URL pública** final (`https://…`). Sin ella no se puede escribir `og:image` absoluta.
5. **Color de marca** (para `theme-color` y fondo de la og-image). Si no lo tiene, sácalo del logo.

Si el usuario dice "luego te paso el logo": deja el `<head>` cableado con la plantilla, los
`<link>` apuntando a los archivos que aún no existen y un `TODO` visible, y díselo en el resumen.

### Paso 1 · Genera los iconos y la og-image

```bash
scripts/generate-icons.sh logo.svg -o public --bg '#ffffff' --og-bg '#0f172a'
```

Produce en `public/` (o la carpeta estática del stack — ver Paso 2):

| Archivo | Tamaño | Para qué |
|---|---|---|
| `favicon.ico` | 16/32/48 | fallback universal; Safari lo usa siempre |
| `favicon.svg` | vector | Chrome/Firefox, nítido y respeta dark mode |
| `apple-touch-icon.png` | 180×180, opaco, con margen | iOS "Añadir a inicio"; iMessage |
| `icon-192.png`, `icon-512.png` | transparentes | manifest, Android, splash |
| `icon-maskable-512.png` | 512, opaco, 20 % margen | Android con máscara |
| `og-image.png` | 1200×630, opaco | preview al compartir |

Reglas que el script ya aplica y no hay que deshacer: **apple-touch y og-image con fondo opaco**
(iOS y los clientes en modo oscuro pintan negro lo transparente), **og-image < 300 KB** (límite
práctico de WhatsApp; si pasa, `--og-format jpg`), **favicon.ico sin margen** (a 16 px cualquier
margen se come el logo). Se niega a sobrescribir iconos existentes salvo con `--force`.

La og-image por defecto es sólo el logo centrado sobre el color de marca. Si el proyecto merece
logo + nombre + tagline, edita `templates/og-image.html` y captúralo con Chrome headless (el
comando está en el propio archivo). Copia después `site.webmanifest` desde `templates/` y rellena
nombre, colores y descripción.

### Paso 2 · Cablea el `<head>` según el stack

| Stack | Estáticos en | Tags en | Plantilla |
|---|---|---|---|
| HTML / Vite (React, Vue, Svelte) | `public/` | `index.html` | `templates/head.html` |
| Laravel / Blade | `public/` | layout → `<x-meta />` | `templates/laravel/meta.blade.php` |
| Filament | `public/` | `PanelProvider->favicon()` | `references/frameworks.md` |
| Next.js App Router | `app/` (convención) | `app/layout.tsx` | `templates/next/layout-metadata.ts` |
| Nuxt | `public/` | `app.vue` | `templates/nuxt/seo.ts` |
| Astro, Django, Rails, Pages Router | ver | `references/frameworks.md` | `templates/head.html` |

Cuatro reglas que no dependen del stack:

1. **`og:image` absoluta y https.** Relativa = sin preview en Facebook, WhatsApp, LinkedIn y
   Telegram. Es la causa #1. Cada stack tiene su forma de absolutizar (`asset()` + `APP_URL`,
   `metadataBase`, `siteUrl`, `Astro.site`); en `references/frameworks.md` está cada una.
2. **El bloque de tags va al principio de `<head>`**, tras charset y viewport y antes de CSS/JS
   inline. WhatsApp sólo lee los primeros ~300 KB del HTML.
3. **`twitter:card = summary_large_image`**; el resto X lo toma de `og:*`.
4. **Los iconos se sirven desde la raíz** (`/favicon.ico`). Si el bundler los hashea (están en
   `src/`, `resources/`, `app/assets`) las rutas se rompen. Van en la carpeta que se copia sin
   tocar (`public/`).

Si el layout ya trae `<title>` (starter kits de Laravel, `create-next-app`, `create-vite`),
sustitúyelo: no dejes dos.

### Paso 3 · Verifica — no des por hecho que sale

Con la URL pública desplegada:

```bash
scripts/check-meta.sh https://ejemplo.com
```

Pide la página como `facebookexternalhit` y comprueba: HTTP 200 sin redirección rara, todos los
`og:*`, `twitter:card`, byte donde empiezan los tags, `og:image` absoluta/https/200/`image/*`/
< 300 KB/dimensiones, `favicon.ico`, `apple-touch-icon`, manifest y `theme-color`. Sale con 1 si
hay fallos. Un `200 text/html` para `/favicon.ico` es un 404 disfrazado que cayó al catch-all.

Sin URL pública aún (sólo local): valida el HTML con el script contra `http://127.0.0.1:PORT`
(fallará sólo el check de https, esperable) y anota que la verificación real queda pendiente
del despliegue.

Prueba final que no sustituye ningún script: **mandarse el link por WhatsApp** y pasarlo por el
[Sharing Debugger de Facebook](https://developers.facebook.com/tools/debug/) (también refresca
la caché de WhatsApp) y el [Post Inspector de LinkedIn](https://www.linkedin.com/post-inspector/).

### Cuando el preview no sale

Casi nunca es el HTML: es una `og:image` relativa, la caché del crawler, una imagen de más de
300 KB, un staging con auth, o el bundler hasheando los iconos. Síntoma → causa → arreglo en
`references/gotchas.md`. Si cambiaste la imagen y sigue saliendo la vieja, versiona la URL
(`og-image.png?v=2`) antes de tocar nada más.

## 2 · Teléfonos: validar y guardar en E.164

Aplica a cualquier campo de teléfono, celular o WhatsApp, en alta o edición.

1. **Input** `type="tel" inputmode="tel" autocomplete="tel"`. Nunca `type="number"` (pierde el
   `+` y los ceros) ni `pattern`/`maxlength` estrictos: la validación real es del servidor.
2. **Acepta lo que escriban** (`55 1234 5678`, `(55) 1234-5678`, `+52 1 55…`, `044 55…`) y
   **valida con libphonenumber**, no con una regex propia. País por defecto: el del proyecto (MX).
3. **Guarda E.164** (`+525512345678`) y **muestra en formato nacional** (`55 1234 5678`).
4. **Servidor siempre**; cliente sólo para UX.

Helpers ya probados, con la limpieza de los formatos viejos de México que libphonenumber rechaza
(`+52 1` de celulares —el que muestra WhatsApp—, `044`, `045`, `01`):

| Stack | Instala | Copia |
|---|---|---|
| JS/TS | `npm i libphonenumber-js` | `templates/phone/phone.ts` → `lib/phone.ts` |
| Laravel | `composer require propaganistas/laravel-phone` (opcional; sin él sólo valida MX) | `templates/laravel/phone/Phone.php` → `app/Support/`, `PhoneRule.php` → `app/Rules/` |
| Python / Rails | `phonenumbers` / `phonelib` | misma lógica, ver `references/telefono.md` |

Usa `normalizePhone()` / `Phone::toE164()` en el `prepareForValidation` o en el mutator del
modelo, para que nunca entre nada sin normalizar. No pongas reglas de "sólo celular": en México
no se distingue fijo de móvil desde 2019. Si hay datos viejos en la BD, normalízalos **antes** de
activar la validación o dejarán de pasar al editar. Detalle y trampas en `references/telefono.md`.

## 3 · Contraseñas: ojo de mostrar/ocultar en todos los inputs

**Todo** `<input type="password">` lleva el toggle: login, registro, confirmar, cambiar, contraseña
actual. Si un formulario lo tiene y otro no, está mal. Requisitos que cumplen las plantillas:
`<button type="button">` (si no, envía el formulario), alternar `input.type` entre `password` y
`text` (lo único compatible con gestores de contraseñas), `aria-label` + `aria-pressed` que
cambian, SVG inline `aria-hidden`, `autocapitalize/autocorrect/spellcheck` apagados, cursor y valor
conservados, estado inicial oculto, y **no tocar `autocomplete`**.

| Stack | Copia / usa |
|---|---|
| Filament | `TextInput::make('password')->password()->revealable()` — ya lo trae |
| Laravel Blade + Alpine (Breeze, Jetstream, Livewire) | `templates/laravel/input-password.blade.php` → `components/input-password.blade.php`; sustituye los inputs de `auth/*` y `profile/*` |
| React / Next | `templates/password/PasswordInput.tsx` |
| Vue / Nuxt (3.4+) | `templates/password/PasswordInput.vue` |
| HTML plano, plantillas heredadas, Django/Rails | `templates/password/password-toggle.js` con `<script defer>`: mejora todos los `input[type=password]`, también los que aparezcan después |
| shadcn, Vuetify, PrimeVue, Quasar… | traen el suyo; úsalo |

Busca los que faltan con `grep -rn 'type="password"' resources/ src/ app/ templates/` y no dejes
ninguno sin ojo. Detalle en `references/password.md`.

## Referencias

- `references/frameworks.md` — dónde van los archivos y los tags en cada stack, y cómo se
  absolutiza `og:image` en cada uno.
- `references/gotchas.md` — las 15 causas de "no sale el logo al compartir", con comprobación.
- `references/telefono.md` — regla completa, formatos viejos de México, por stack, migración de datos.
- `references/password.md` — requisitos del toggle, por stack, trampas (Livewire, `type=button`, `x-cloak`).
- `scripts/generate-icons.sh` — logo → set completo de iconos + og-image (ImageMagick).
- `scripts/check-meta.sh` — verifica una URL como lo haría el crawler de Facebook/WhatsApp.
- `templates/` — `head.html`, `site.webmanifest`, `og-image.html`; `laravel/` (meta, input-password,
  phone), `next/`, `nuxt/`, `phone/phone.ts`, `password/` (vanilla, React, Vue).
