<!--
  components/PasswordInput.vue — <input type="password"> con ojo de mostrar/ocultar. Vue 3.4+.
  Sin dependencias (SVG inline). Clases Tailwind: cámbialas si el proyecto usa otra cosa.

    <PasswordInput v-model="form.password" name="password" autocomplete="current-password" required />

  Úsalo para TODOS los campos de contraseña: login, registro, confirmar, cambiar contraseña.
-->
<script setup lang="ts">
import { ref, useId } from 'vue'

defineOptions({ inheritAttrs: false })
const model = defineModel<string>({ default: '' })
const show = ref(false)
const id = useId()
</script>

<template>
  <div class="relative">
    <input
      v-bind="$attrs"
      :id="($attrs.id as string) ?? id"
      v-model="model"
      :type="show ? 'text' : 'password'"
      autocapitalize="off"
      autocorrect="off"
      spellcheck="false"
      class="w-full rounded-md border border-gray-300 px-3 py-2 pr-11 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
    />
    <button
      type="button"
      :aria-label="show ? 'Ocultar contraseña' : 'Mostrar contraseña'"
      :aria-pressed="show"
      class="absolute inset-y-0 right-0 flex w-11 items-center justify-center rounded-md text-gray-500 hover:text-gray-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-indigo-500"
      @click="show = !show"
    >
      <svg v-if="show" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 10 8 10 8a13.16 13.16 0 0 1-1.67 2.68" />
        <path d="M6.61 6.61A13.5 13.5 0 0 0 2 12s3 8 10 8a9.74 9.74 0 0 0 5.39-1.61" />
        <path d="M14.12 14.12a3 3 0 1 1-4.24-4.24" />
        <path d="M2 2l20 20" />
      </svg>
      <svg v-else class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z" />
        <circle cx="12" cy="12" r="3" />
      </svg>
    </button>
  </div>
</template>
