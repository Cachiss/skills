// Validación y normalización de teléfonos con libphonenumber-js.
//   npm i libphonenumber-js
//
// Regla: se acepta lo que el usuario escriba ("55 1234 5678", "(55) 1234-5678", "+52 1 55…"),
// se valida con libphonenumber y se GUARDA en E.164 ("+525512345678"). Se muestra en formato
// nacional. Nunca se guarda lo que tecleó el usuario tal cual.
//
// México: desde agosto de 2019 los números son 10 dígitos sin prefijos. libphonenumber rechaza
// los formatos viejos que siguen circulando (+52 1 …, 044, 045, 01). Se limpian antes de validar.
import { parsePhoneNumberFromString, AsYouType, type CountryCode } from 'libphonenumber-js'

export const DEFAULT_COUNTRY: CountryCode = 'MX'

/** Quita prefijos mexicanos anteriores a 2019: "+52 1 55…" → "+52 55…", "044/045/01 + 10 dígitos" → 10 dígitos. */
export function stripMxLegacyPrefixes(raw: string): string {
  const s = raw.replace(/[^\d+]/g, '')
  if (/^\+?521\d{10}$/.test(s)) return '+52' + s.slice(-10)          // +52 1 + 10 dígitos (celulares viejos, WhatsApp)
  if (/^(044|045|01)\d{10}$/.test(s)) return s.slice(-10)              // marcación nacional vieja
  return s
}

/** Devuelve el número en E.164 o null si no es válido. */
export function normalizePhone(raw: string, country: CountryCode = DEFAULT_COUNTRY): string | null {
  const cleaned = country === 'MX' ? stripMxLegacyPrefixes(raw) : raw
  const parsed = parsePhoneNumberFromString(cleaned, country)
  return parsed?.isValid() ? parsed.number : null
}

export function isValidPhone(raw: string, country: CountryCode = DEFAULT_COUNTRY): boolean {
  return normalizePhone(raw, country) !== null
}

/** "+525512345678" → "55 1234 5678" (para mostrar). Si no parsea, devuelve el valor tal cual. */
export function formatPhone(e164: string, country: CountryCode = DEFAULT_COUNTRY): string {
  return parsePhoneNumberFromString(e164, country)?.formatNational() ?? e164
}

/** Link de WhatsApp: dígitos sin "+" → https://wa.me/525512345678 */
export function whatsappLink(e164: string, text?: string): string {
  const url = `https://wa.me/${e164.replace(/\D/g, '')}`
  return text ? `${url}?text=${encodeURIComponent(text)}` : url
}

/** Formatea mientras el usuario escribe (onInput). Mantiene el "+" si lo tecleó. */
export function formatAsYouType(raw: string, country: CountryCode = DEFAULT_COUNTRY): string {
  return new AsYouType(country).input(raw)
}

// --- Zod (opcional) -----------------------------------------------------------------------
// import { z } from 'zod'
// export const phoneSchema = z.string().trim()
//   .transform((v, ctx) => {
//     const e164 = normalizePhone(v)
//     if (!e164) { ctx.addIssue({ code: 'custom', message: 'Teléfono no válido' }); return z.NEVER }
//     return e164
//   })
