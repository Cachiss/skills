# Herramientas

Este archivo documenta las herramientas existentes antes de proponer cambios. Una herramienta no se migra, integra, reemplaza ni modifica solo porque exista una alternativa nueva.

## Inventario

| ID | Herramienta | Versión o plan | Responsable | Usuarios | Función actual | Criticidad | Evidencia |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H-001 |  |  |  |  |  | Alta, media o baja | E-001 |

## Uso actual

| ID | Herramienta | Entrada | Pasos reales | Salida | Destino | Frecuencia | Volumen | Problema observado |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| UH-001 | H-001 |  |  |  |  |  |  |  |

## Datos

| Herramienta | Datos | Fuente de verdad | Formato de entrada | Formato de salida | Propietario | Sensibilidad | Retención |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H-001 |  | Sí, No o Parcial |  |  |  |  |  |

## Capacidades

| Herramienta | API | Webhooks | Importación | Exportación | Autenticación | Permisos | Límites | Estado de verificación |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| H-001 |  |  |  |  |  |  |  | No verificado |

Las capacidades se verifican mediante uso real, configuración, exportaciones o documentación oficial vigente. Un documento heredado no basta para confirmarlas.

## Dependencias

| ID | Herramienta | Depende de | Consumida por | Riesgo si cambia | Evidencia |
| --- | --- | --- | --- | --- | --- |
| DH-001 | H-001 |  |  |  | E-001 |

## Opciones

| ID | Herramienta | Opción | Problema que resuelve | Valor añadido | Costo o riesgo | Reversibilidad | Métrica | Estado | Memoria |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OH-001 | H-001 | Conservar, configurar, formatear, integrar, migrar, reemplazar o retirar |  |  |  |  |  | En duda | M-001 |

## Valor

Toda propuesta debe comparar:

| Dimensión | Situación actual | Cambio propuesto | Mejora esperada | Cómo se comprobará |
| --- | --- | --- | --- | --- |
| Tiempo, calidad, costo, riesgo o experiencia |  |  |  |  |

## Decisión

La autoridad final elige la opción. Antes de confirmarla deben estar claros:

- El problema real que se intenta resolver.
- El valor que ya aporta la herramienta.
- Los usuarios y procesos afectados.
- La propiedad, calidad y portabilidad de los datos.
- Las integraciones y dependencias existentes.
- Los costos, riesgos y restricciones contractuales.
- La convivencia temporal y reversión, si hay migración.
- La métrica que demostrará valor añadido.

Si falta información material, la opción permanece `En duda` y se conserva en la memoria de trabajo.
