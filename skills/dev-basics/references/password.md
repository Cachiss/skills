# Contraseñas: el ojo de mostrar/ocultar

**Todo** `<input type="password">` lleva el toggle: login, registro, confirmar contraseña, cambiar
contraseña, contraseña actual, PIN. Sin excepciones "porque es sólo el admin". Es lo que más
reduce errores de tecleo y peticiones de "restablecer contraseña".

## Qué tiene que cumplir

| Requisito | Por qué |
|---|---|
| `<button type="button">` | sin `type`, el botón dentro de un `<form>` es submit: el clic en el ojo envía el formulario |
| Cambiar `input.type` entre `password` y `text` | es lo único que funciona con autocompletado, gestores de contraseñas y lectores de pantalla; nada de `-webkit-text-security` ni fuentes de puntos |
| `aria-label` que cambie ("Mostrar contraseña" / "Ocultar contraseña") + `aria-pressed` | el icono solo no dice nada a un lector de pantalla |
| Icono SVG inline con `aria-hidden="true"` | sin dependencia de iconos; el label lo pone el botón |
| `autocapitalize="off" autocorrect="off" spellcheck="false"` en el input | al pasar a `text`, el móvil intenta capitalizar y autocorregir la contraseña |
| Conservar el valor y el cursor al alternar | cambiar `type` conserva el valor, pero algunos navegadores mandan el cursor al final: se restaura con `setSelectionRange` |
| Estado inicial **oculto** | siempre; no recordar el estado entre páginas |
| `autocomplete="current-password"` / `"new-password"` | no lo quites por añadir el toggle: es lo que hace que el gestor de contraseñas rellene el campo correcto |

El `padding-right` del input debe dejar sitio al botón (≈ 2.75 rem) para que el texto no pase por
debajo del ojo.

## Por stack

| Stack | Cómo | Plantilla |
|---|---|---|
| Filament | `TextInput::make('password')->password()->revealable()` — viene de serie | — |
| Laravel Blade (Breeze, Jetstream, Livewire) | componente Alpine `<x-input-password />` | `templates/laravel/input-password.blade.php` |
| React / Next | `<PasswordInput />` | `templates/password/PasswordInput.tsx` |
| Vue / Nuxt | `<PasswordInput />` (Vue 3.4+) | `templates/password/PasswordInput.vue` |
| HTML plano, plantillas heredadas, Django/Rails sin componentes | script que mejora todos los `input[type=password]` | `templates/password/password-toggle.js` |
| shadcn/ui, Vuetify, PrimeVue, Quasar, Element | traen input de contraseña con toggle (`Password` de PrimeVue, `append-inner-icon` en Vuetify, …): úsalo, no lo reimplementes | — |

Sustituye los inputs de contraseña existentes por el componente; no dejes unos con ojo y otros sin.
Con Breeze, los formularios a tocar son `auth/login`, `auth/register`, `auth/reset-password`,
`auth/confirm-password` y `profile/partials/update-password-form`.

### El script vanilla

Envuelve cada input en un `div.pw-field` y añade el botón. Copia `display`, `width`, `flex` y
`grid-column` del input al wrapper para que el layout no cambie; está probado con inputs block
`w-full`, inline, `flex: 1` y añadidos dinámicamente (MutationObserver). Para excluir uno:
`data-no-toggle`.

Con **Livewire** el morphing puede quitar el wrapper al re-renderizar y el observer lo vuelve a
poner (parpadeo). Ahí usa el componente Blade, que Livewire respeta.

## Trampas

- **Botón sin `type="button"`** → envía el formulario. Es el fallo #1.
- **El ojo tapa el icono de error** o el de Safari/1Password: si el input ya tiene un icono a la
  derecha, mueve el ojo a la izquierda de ese icono con más `padding-right`, o quita el otro.
- **Toggle con `onmousedown` + `onmouseup`** ("mantener para ver"): no funciona con teclado ni
  con lectores de pantalla. Clic que alterna, siempre.
- **`x-cloak` sin CSS**: en Blade/Alpine el segundo SVG parpadea al cargar si falta
  `[x-cloak]{display:none!important}`. Breeze lo trae; en un layout propio, añádelo.
- **Toggle en `<input type="password">` con `autocomplete="one-time-code"`** (códigos OTP): no
  hace falta; muéstralos como `text` directamente.
