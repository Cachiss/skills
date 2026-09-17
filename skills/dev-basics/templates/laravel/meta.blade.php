{{--
  resources/views/components/meta.blade.php  →  <x-meta />

  Pégalo al principio de <head> del layout, después de charset y viewport:
      <x-meta />
  Por página, sobrescribe lo que cambie:
      <x-meta title="Precios" description="Planes desde $99" :image="asset('og/precios.png')" />

  Añade a config/app.php:
      'description' => env('APP_DESCRIPTION', 'Qué hace el proyecto en una frase.'),
      'theme_color' => env('APP_THEME_COLOR', '#0f172a'),

  asset() y url() construyen URLs ABSOLUTAS a partir de APP_URL: si APP_URL está mal (http://,
  localhost, otro dominio), og:image sale mal y no hay preview. Detrás de Traefik/Dokploy además
  hace falta trustProxies + forceScheme('https') — ver skill laravel-dokploy.
--}}
@props([
    'title' => null,
    'description' => config('app.description'),
    'image' => asset('og-image.png'),
    'type' => 'website',
])
@php
    $siteName = config('app.name');
    $fullTitle = $title ? "{$title} · {$siteName}" : $siteName;
    $url = url()->current();
@endphp
<title>{{ $fullTitle }}</title>
<meta name="description" content="{{ $description }}">
<link rel="canonical" href="{{ $url }}">
<meta name="theme-color" content="{{ config('app.theme_color', '#ffffff') }}">

<link rel="icon" href="{{ asset('favicon.ico') }}" sizes="32x32">
<link rel="icon" href="{{ asset('favicon.svg') }}" type="image/svg+xml">
<link rel="apple-touch-icon" href="{{ asset('apple-touch-icon.png') }}">
<link rel="manifest" href="{{ asset('site.webmanifest') }}">

<meta property="og:type" content="{{ $type }}">
<meta property="og:site_name" content="{{ $siteName }}">
<meta property="og:title" content="{{ $fullTitle }}">
<meta property="og:description" content="{{ $description }}">
<meta property="og:url" content="{{ $url }}">
<meta property="og:image" content="{{ $image }}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="Logo de {{ $siteName }}">
<meta property="og:locale" content="{{ str_replace('-', '_', config('app.locale', 'es')) }}">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{{ $fullTitle }}">
<meta name="twitter:description" content="{{ $description }}">
<meta name="twitter:image" content="{{ $image }}">
