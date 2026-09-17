<?php

// app/Support/Phone.php — normaliza y formatea teléfonos. Guarda siempre E.164 ("+525512345678").
//
// Usa libphonenumber si está instalado (composer require propaganistas/laravel-phone, que lo trae),
// y si no, cae a una validación mínima: MX = 10 dígitos, resto = E.164 con "+" y 8–15 dígitos.
//
// México: desde agosto de 2019 los números son 10 dígitos sin prefijos. libphonenumber rechaza los
// formatos viejos que siguen circulando (+52 1 …, 044, 045, 01): se limpian ANTES de validar.

namespace App\Support;

use libphonenumber\PhoneNumberFormat;
use libphonenumber\PhoneNumberUtil;

final class Phone
{
    public const DEFAULT_COUNTRY = 'MX';

    /** "+52 1 55 1234 5678" → "+525512345678"; "044 55 1234 5678" → "5512345678". */
    public static function stripMxLegacyPrefixes(string $raw): string
    {
        $s = preg_replace('/[^\d+]/', '', $raw) ?? '';

        if (preg_match('/^\+?521(\d{10})$/', $s, $m)) {
            return '+52'.$m[1];                     // +52 1 + 10 dígitos (celulares viejos, WhatsApp)
        }
        if (preg_match('/^(?:044|045|01)(\d{10})$/', $s, $m)) {
            return $m[1];                           // marcación nacional vieja
        }

        return $s;
    }

    /** E.164 o null si no es válido. */
    public static function toE164(?string $raw, string $country = self::DEFAULT_COUNTRY): ?string
    {
        if ($raw === null || trim($raw) === '') {
            return null;
        }

        $cleaned = $country === 'MX' ? self::stripMxLegacyPrefixes($raw) : preg_replace('/[^\d+]/', '', $raw);

        if (class_exists(PhoneNumberUtil::class)) {
            try {
                $util = PhoneNumberUtil::getInstance();
                $number = $util->parse($cleaned, $country);

                return $util->isValidNumber($number) ? $util->format($number, PhoneNumberFormat::E164) : null;
            } catch (\Throwable) {
                return null;
            }
        }

        // Fallback sin libphonenumber
        if ($country === 'MX') {
            if (preg_match('/^(?:\+?52)?(\d{10})$/', $cleaned, $m)) {
                return '+52'.$m[1];
            }

            return null;
        }

        return preg_match('/^\+[1-9]\d{7,14}$/', $cleaned) ? $cleaned : null;
    }

    public static function isValid(?string $raw, string $country = self::DEFAULT_COUNTRY): bool
    {
        return self::toE164($raw, $country) !== null;
    }

    /** "+525512345678" → "55 1234 5678" (para mostrar). */
    public static function format(?string $e164, string $country = self::DEFAULT_COUNTRY): string
    {
        if ($e164 === null || $e164 === '') {
            return '';
        }

        if (class_exists(PhoneNumberUtil::class)) {
            try {
                $util = PhoneNumberUtil::getInstance();

                return $util->format($util->parse($e164, $country), PhoneNumberFormat::NATIONAL);
            } catch (\Throwable) {
                return $e164;
            }
        }

        if (preg_match('/^\+52(\d{2})(\d{4})(\d{4})$/', $e164, $m)) {
            return "{$m[1]} {$m[2]} {$m[3]}";
        }

        return $e164;
    }

    /** https://wa.me/525512345678?text=... (dígitos sin "+"). */
    public static function whatsappLink(string $e164, ?string $text = null): string
    {
        $url = 'https://wa.me/'.preg_replace('/\D/', '', $e164);

        return $text ? $url.'?text='.rawurlencode($text) : $url;
    }
}
