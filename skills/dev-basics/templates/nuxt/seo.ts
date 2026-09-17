// Nuxt 3/4 — pega en <script setup> de app.vue (o layouts/default.vue). Iconos en public/.
//
// nuxt.config.ts:
//   runtimeConfig: { public: { siteUrl: process.env.NUXT_PUBLIC_SITE_URL || 'https://ejemplo.com' } }
//
// Nuxt NO convierte ogImage en absoluta por ti: constrúyela con siteUrl.
// (Alternativa con más automatismo: módulo @nuxtjs/seo → nuxt-og-image, nuxt-seo-utils.)
const { public: { siteUrl } } = useRuntimeConfig()
const route = useRoute()

const SITE_NAME = 'Proyecto'
const DESCRIPTION = 'Qué hace el proyecto en una frase (≤ 160 caracteres).'
const THEME = '#0f172a'

useHead({
  titleTemplate: (t) => (t ? `${t} · ${SITE_NAME}` : SITE_NAME),
  link: [
    { rel: 'icon', href: '/favicon.ico', sizes: '32x32' },
    { rel: 'icon', href: '/favicon.svg', type: 'image/svg+xml' },
    { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
    { rel: 'manifest', href: '/site.webmanifest' },
    { rel: 'canonical', href: () => `${siteUrl}${route.path}` },
  ],
  meta: [{ name: 'theme-color', content: THEME }],
})

useSeoMeta({
  description: DESCRIPTION,
  ogType: 'website',
  ogSiteName: SITE_NAME,
  ogTitle: SITE_NAME,
  ogDescription: DESCRIPTION,
  ogUrl: () => `${siteUrl}${route.path}`,
  ogImage: `${siteUrl}/og-image.png`,
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageAlt: `Logo de ${SITE_NAME}`,
  ogLocale: 'es_MX',
  twitterCard: 'summary_large_image',
})
