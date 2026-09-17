// app/layout.tsx (App Router, Next 14/15) — mezcla estos exports con los que ya tengas.
//
// Iconos por convención de archivos (Next genera los <link>/<meta> solo):
//   app/icon.svg  ó  app/icon.png        → <link rel="icon">
//   app/apple-icon.png (180x180)         → <link rel="apple-touch-icon">
//   app/opengraph-image.png (1200x630)   → og:image + og:image:width/height
//   app/twitter-image.png (opcional; si falta, X usa og:image)
//   public/favicon.ico                   → sigue sirviéndose en /favicon.ico
//
// metadataBase es OBLIGATORIO: sin él, en producción og:image sale relativa (o apunta a
// localhost) y no hay preview. Next avisa en consola pero no falla el build.
import type { Metadata, Viewport } from 'next'

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://ejemplo.com'
const SITE_NAME = 'Proyecto'
const DESCRIPTION = 'Qué hace el proyecto en una frase (≤ 160 caracteres).'

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: { default: SITE_NAME, template: `%s · ${SITE_NAME}` },
  description: DESCRIPTION,
  alternates: { canonical: '/' },
  manifest: '/site.webmanifest',
  openGraph: {
    type: 'website',
    siteName: SITE_NAME,
    title: SITE_NAME,
    description: DESCRIPTION,
    url: '/',
    locale: 'es_MX',
    // Si prefieres public/og-image.png en vez de app/opengraph-image.png:
    // images: [{ url: '/og-image.png', width: 1200, height: 630, alt: `Logo de ${SITE_NAME}` }],
  },
  twitter: { card: 'summary_large_image' },
  // Si dejas los iconos en public/ en vez de app/:
  // icons: {
  //   icon: [{ url: '/favicon.ico', sizes: '32x32' }, { url: '/favicon.svg', type: 'image/svg+xml' }],
  //   apple: '/apple-touch-icon.png',
  // },
}

// theme-color va en viewport desde Next 14 (en metadata está deprecado y avisa en consola).
export const viewport: Viewport = { themeColor: '#0f172a' }
