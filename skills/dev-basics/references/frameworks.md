# Dónde va cada cosa según el stack

Regla general: los iconos y la og-image se sirven **desde la raíz del dominio** (`/favicon.ico`,
`/og-image.png`) y los tags viven en el **layout raíz**, al principio de `<head>`. Lo que cambia
por stack es qué carpeta se sirve como raíz y cómo se construye la URL absoluta de `og:image`.

| Stack | Archivos estáticos | Tags | URL absoluta de og:image |
|---|---|---|---|
| HTML plano / Vite (React, Vue, Svelte) | `public/` | `index.html` | escribirla a mano |
| Laravel / Blade | `public/` | layout → `<x-meta />` | `asset()` con `APP_URL` correcto |
| Filament | `public/` | `PanelProvider` | `asset()` |
| Next.js App Router | `app/` (convención) o `public/` | `app/layout.tsx` → `metadata` | `metadataBase` |
| Next.js Pages Router | `public/` | `pages/_app.tsx` → `<Head>` | escribirla a mano / env |
| Nuxt 3/4 | `public/` | `app.vue` → `useSeoMeta` | `runtimeConfig.public.siteUrl` |
| Astro | `public/` | `src/layouts/Layout.astro` | `new URL('/og-image.png', Astro.site)` |
| Django | `static/` + `STATIC_URL` | `templates/base.html` | `request.build_absolute_uri` |
| Rails | `public/` | `app/views/layouts/application.html.erb` | `image_url` (no `image_path`) |

## HTML plano · Vite

- Iconos en `public/` (Vite los copia tal cual a la raíz del build; en `src/` los hashea y rompe
  las rutas `/favicon.ico`).
- Tags en `index.html`. Vite interpola `%VITE_APP_TITLE%` desde `.env` si quieres parametrizar.
- **Es una SPA**: los crawlers no ejecutan JS. Lo que hay en `index.html` es lo único que ven, así
  que el preview será el mismo para todas las rutas. Si hace falta preview por ruta → SSR o
  prerender (vite-plugin-ssr / vite-ssg / Nuxt / Next).

## Laravel · Blade

1. Iconos y `og-image.png` en `public/` (no en `resources/`: Vite los hashearía).
2. `templates/laravel/meta.blade.php` → `resources/views/components/meta.blade.php`.
3. En el layout (`resources/views/layouts/app.blade.php` o `components/layouts/app.blade.php`):
   ```blade
   <head>
       <meta charset="utf-8">
       <meta name="viewport" content="width=device-width, initial-scale=1">
       <x-meta />
       @vite(['resources/css/app.css', 'resources/js/app.js'])
   ```
4. `config/app.php`: añade `description` y `theme_color` (ver comentario de la plantilla).
5. `APP_URL` en `.env` de producción **con https y el dominio real**. `asset()` lo usa para
   construir `og:image`; con `APP_URL=http://localhost` el preview no sale en producción.
6. Detrás de proxy (Dokploy/Traefik, Forge con LB): `trustProxies` + `URL::forceScheme('https')`
   en `AppServiceProvider`, o `url()->current()` devolverá `http://` — skill `laravel-dokploy`.

Si el proyecto tiene starter kit (Breeze/Jetstream/Livewire starter), el layout ya trae `<title>`:
sustitúyelo, no lo dupliques.

## Filament

Filament no pasa por el layout de la app; se configura en el `PanelProvider`:

```php
return $panel
    ->favicon(asset('favicon.ico'))          // o favicon.svg
    ->brandLogo(asset('logo.svg'))           // logo en la barra lateral / login
    ->brandLogoHeight('2rem')
    ->brandName(config('app.name'));
```

Para inyectar OG tags en el panel (rara vez necesario: suele ir detrás de login):

```php
use Filament\Support\Facades\FilamentView;
use Filament\View\PanelsRenderHook;

FilamentView::registerRenderHook(PanelsRenderHook::HEAD_START, fn () => view('components.meta'));
```

## Next.js · App Router (14/15)

Convención de archivos en `app/` — Next genera los tags solo:

```
app/icon.svg  ó  app/icon.png         → <link rel="icon">
app/apple-icon.png    (180x180)       → <link rel="apple-touch-icon">
app/opengraph-image.png (1200x630)    → og:image + width/height
app/twitter-image.png (opcional)
app/manifest.ts  ó  public/site.webmanifest
public/favicon.ico                    → /favicon.ico (Safari, navegadores viejos)
```

`templates/next/layout-metadata.ts` → mezclar en `app/layout.tsx`. Lo único que no puede faltar:
**`metadataBase`**. Sin él, `og:image` sale relativa en producción y Next sólo avisa en consola.

`themeColor` va en `export const viewport`, no en `metadata` (deprecado en 14, avisa en consola).

Por página: `export const metadata = { title: 'Precios' }` hereda el resto del layout; para OG
dinámico por ruta, `app/<ruta>/opengraph-image.tsx` con `ImageResponse`.

## Next.js · Pages Router

```tsx
// pages/_app.tsx
import Head from 'next/head'
<Head>
  {/* contenido de templates/head.html, con la URL desde process.env.NEXT_PUBLIC_SITE_URL */}
</Head>
```
Iconos en `public/`. `next/head` deduplica por `key` si una página sobrescribe `og:title`.

## Nuxt 3/4

- Iconos en `public/`.
- `templates/nuxt/seo.ts` → `<script setup>` de `app.vue`. Define `runtimeConfig.public.siteUrl`
  en `nuxt.config.ts`; `useSeoMeta` no absolutiza `ogImage` por ti.
- Alternativa con más automatismo: `@nuxtjs/seo` (`nuxt-og-image` genera la imagen desde un
  componente Vue, `nuxt-seo-utils` rellena canonical/og:url).
- Con `ssr: false` aplica lo mismo que a una SPA de Vite.

## Astro

```astro
---
// src/layouts/Layout.astro · requiere `site: 'https://ejemplo.com'` en astro.config.mjs
const ogImage = new URL('/og-image.png', Astro.site);
const canonical = new URL(Astro.url.pathname, Astro.site);
---
<head>
  <!-- templates/head.html, usando {ogImage} y {canonical} -->
```
Iconos en `public/`. Sin `site` en la config, `Astro.site` es `undefined` y `new URL` lanza.

## Django

`templates/base.html` con `{% load static %}` y `{% static 'favicon.ico' %}`. Para `og:image`
absoluta: `{{ request.scheme }}://{{ request.get_host }}{% static 'og-image.png' %}` o
`request.build_absolute_uri(static('og-image.png'))` desde una context processor. Con
`STATIC_URL='/static/'` el favicon queda en `/static/favicon.ico`: añade además una ruta o una
regla en nginx para `/favicon.ico` (los navegadores lo buscan ahí sin mirar el HTML).

## Rails

`app/views/layouts/application.html.erb`. Iconos en `public/` (no en `app/assets/images`: el
asset pipeline les cambia el nombre). `og:image` con `image_url` — `image_path` devuelve relativa.
