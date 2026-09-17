<?php

// app/Rules/PhoneRule.php — regla de validación. Uso en un FormRequest:
//
//     'telefono' => ['required', new PhoneRule],          // país por defecto (MX)
//     'telefono' => ['nullable', new PhoneRule('US')],
//
// Y en prepareForValidation() o en un mutator, guarda normalizado:
//
//     protected function prepareForValidation(): void
//     {
//         $this->merge(['telefono' => Phone::toE164($this->telefono) ?? $this->telefono]);
//     }
//
// Alternativa con paquete: composer require propaganistas/laravel-phone → 'telefono' => 'phone:MX'.
// Ojo: ese paquete NO limpia el "+52 1" viejo; sigue usando Phone::toE164() antes de validar.
// Y no uses 'phone:MX,mobile': en México no se distingue móvil de fijo desde 2019.

namespace App\Rules;

use App\Support\Phone;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

final class PhoneRule implements ValidationRule
{
    public function __construct(private readonly string $country = Phone::DEFAULT_COUNTRY) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value) || ! Phone::isValid($value, $this->country)) {
            $fail('El :attribute no es un teléfono válido.');
        }
    }
}
