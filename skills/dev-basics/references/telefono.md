# Teléfonos: validar, normalizar, guardar

## La regla

1. **Se acepta lo que el usuario escriba**: `55 1234 5678`, `(55) 1234-5678`, `+52 55 1234 5678`,
   `+52 1 55 1234 5678`, `044 55…`. No se le obliga a un formato ni se le rechaza por un espacio.
2. **Se valida con libphonenumber** (la librería de Google; hay port para cada lenguaje). Nunca
   con una regex escrita a mano salvo el fallback MX de 10 dígitos.
3. **Se guarda en E.164**: `+525512345678`. Un solo formato en la BD → se puede buscar, deduplicar,
   mandar SMS/WhatsApp y comparar sin sorpresas.
4. **Se muestra en formato nacional**: `55 1234 5678`.
5. **Se valida en servidor siempre**; en cliente sólo para UX.

## El input

```html
<input type="tel" inputmode="tel" autocomplete="tel" name="telefono" placeholder="55 1234 5678">
```

- `type="tel"`: teclado numérico en móvil y el navegador autocompleta con el teléfono guardado.
- **Nunca `type="number"`**: quita el `+`, quita ceros a la izquierda, mete flechitas y en iOS el
  teclado no tiene `+`.
- Sin `pattern` ni `maxlength` estrictos: rompen con extensiones internacionales y con los formatos
  viejos que la gente sigue tecleando. La validación real es del servidor.
- Un selector de país sólo si el proyecto es internacional. Si no, país por defecto y ya.

## México en concreto

Desde el 3 de agosto de 2019 (IFT) todos los números son **10 dígitos, sin prefijos**. Pero siguen
circulando los formatos de antes y libphonenumber los **rechaza**:

| Lo que llega | Por qué | Cómo se limpia |
|---|---|---|
| `+52 1 55 1234 5678` / `5215512345678` | el "1" de celular; WhatsApp lo sigue mostrando así, y las BD viejas están llenas | quitar el `1` tras `52` cuando hay 13 dígitos → `+525512345678` |
| `044 55 1234 5678`, `045 55…` | prefijo viejo de celular | quitar `044`/`045` cuando siguen 10 dígitos |
| `01 800 123 4567` | prefijo viejo de larga distancia | quitar `01` cuando siguen 10 dígitos |

`templates/phone/phone.ts` y `templates/laravel/phone/Phone.php` hacen esta limpieza **antes** de
llamar a libphonenumber. Los paquetes (`laravel-phone`, `libphonenumber-js` a pelo) no la hacen.

Otra consecuencia de la unificación: **libphonenumber no distingue móvil de fijo en MX** (devuelve
`FIXED_LINE_OR_MOBILE`). No pongas reglas tipo "sólo celulares": no hay forma de saberlo.

Link de WhatsApp: `https://wa.me/525512345678` — dígitos, sin `+`. Con texto:
`?text=` + `encodeURIComponent(...)`. Los helpers traen `whatsappLink()`.

## Por stack

| Stack | Librería | Plantilla |
|---|---|---|
| JS/TS (React, Vue, Node, Next, Nuxt) | `npm i libphonenumber-js` (~150 KB con metadata `min`; la de Google completa pesa 500 KB+) | `templates/phone/phone.ts` |
| Laravel | `composer require propaganistas/laravel-phone` (trae `giggsey/libphonenumber-for-php`) | `templates/laravel/phone/Phone.php` + `PhoneRule.php` |
| Python | `pip install phonenumbers` | misma lógica: `phonenumbers.parse(cleaned, "MX")`, `is_valid_number`, `format_number(…, E164)` |
| Rails | gem `phonelib` | `Phonelib.parse(cleaned, 'MX').e164` |

Sin libphonenumber, `Phone.php` cae a "MX = 10 dígitos" y rechaza cualquier otro país. Vale para un
proyecto sólo-México; si hay extranjeros, instala el paquete.

### Laravel

```php
// FormRequest
public function rules(): array
{
    return ['telefono' => ['required', new PhoneRule]];
}

protected function prepareForValidation(): void
{
    $this->merge(['telefono' => Phone::toE164($this->telefono) ?? $this->telefono]);
}
```

O como accessor/mutator en el modelo para que **nunca** entre nada sin normalizar:

```php
protected function telefono(): Attribute
{
    return Attribute::make(
        set: fn (?string $v) => Phone::toE164($v) ?? $v,
    );
}
```

En Filament: `TextInput::make('telefono')->tel()->rule(new PhoneRule)->dehydrateStateUsing(fn ($s) => Phone::toE164($s) ?? $s)`.

### JS

```ts
import { normalizePhone, formatPhone } from '@/lib/phone'

const e164 = normalizePhone(form.telefono)     // null si no es válido
if (!e164) errors.telefono = 'Teléfono no válido'
// …enviar e164 al servidor; mostrar formatPhone(e164)
```

Con react-hook-form + zod, el `phoneSchema` comentado al final de `phone.ts` transforma el
campo a E.164 y falla si no es válido.

## Trampas

- **Migrar datos viejos**: antes de activar la validación, pasa `Phone::toE164()` por la columna
  existente. Si no, la mitad de los registros con `+521…` dejarán de pasar la validación al editar.
- **Números de prueba**: `55 1234 5678` es válido para libphonenumber aunque no exista. La
  validación es de *formato*, no de existencia; para eso hace falta OTP por SMS/WhatsApp.
- **`5512345678abc`** pasa (se descartan las letras). Es deliberado: la gente pega cosas raras.
  Si el proyecto necesita rechazar eso, valida `raw` con `/^[\d\s()+\-.]+$/` antes.
- **Un número de EE. UU. sin `+`** (`4155552671`) se interpreta como MX y es válido (10 dígitos).
  Sin código de país no hay forma de distinguirlos: si hay usuarios extranjeros, selector de país.
