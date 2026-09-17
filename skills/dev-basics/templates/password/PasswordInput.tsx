// components/PasswordInput.tsx — <input type="password"> con ojo de mostrar/ocultar.
// Sin dependencias (SVG inline). Clases Tailwind: cámbialas si el proyecto usa otra cosa.
//
//   <PasswordInput name="password" autoComplete="current-password" required />
//   <PasswordInput {...register('password')} autoComplete="new-password" />   // react-hook-form
//
// Úsalo para TODOS los campos de contraseña: login, registro, confirmar, cambiar contraseña.
import { forwardRef, useId, useState, type InputHTMLAttributes } from 'react'

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'type'>

export const PasswordInput = forwardRef<HTMLInputElement, Props>(function PasswordInput(
  { className = '', id, ...props },
  ref,
) {
  const [show, setShow] = useState(false)
  const autoId = useId()
  const inputId = id ?? autoId

  return (
    <div className="relative">
      <input
        ref={ref}
        id={inputId}
        autoCapitalize="off"
        autoCorrect="off"
        spellCheck={false}
        {...props}
        type={show ? 'text' : 'password'}
        className={`w-full rounded-md border border-gray-300 px-3 py-2 pr-11 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 ${className}`}
      />
      <button
        type="button"
        onClick={() => setShow((s) => !s)}
        aria-label={show ? 'Ocultar contraseña' : 'Mostrar contraseña'}
        aria-pressed={show}
        aria-controls={inputId}
        className="absolute inset-y-0 right-0 flex w-11 items-center justify-center rounded-md text-gray-500 hover:text-gray-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-indigo-500"
      >
        {show ? <EyeOff /> : <Eye />}
      </button>
    </div>
  )
})

const svgProps = {
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
  className: 'h-5 w-5',
  'aria-hidden': true,
}

function Eye() {
  return (
    <svg {...svgProps}>
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  )
}

function EyeOff() {
  return (
    <svg {...svgProps}>
      <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 10 8 10 8a13.16 13.16 0 0 1-1.67 2.68" />
      <path d="M6.61 6.61A13.5 13.5 0 0 0 2 12s3 8 10 8a9.74 9.74 0 0 0 5.39-1.61" />
      <path d="M14.12 14.12a3 3 0 1 1-4.24-4.24" />
      <path d="M2 2l20 20" />
    </svg>
  )
}
