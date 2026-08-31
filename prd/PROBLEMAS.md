# Problemas

Este archivo conserva situaciones concretas antes de convertirlas en problemas generales o requisitos.

## Relatos

| ID | Relato observado | Quién lo dijo | Contexto | Consecuencia descrita | Evidencia |
| --- | --- | --- | --- | --- | --- |
| R-001 | “No recordaban si habían pagado al maestro de obra.” |  |  |  | E-001 |

No se corrige ni amplía el relato. Si la frase es una paráfrasis, debe indicarse.

## Hipótesis

| ID | Relato | Posible problema | Qué falta comprobar | Confianza | Estado | Memoria |
| --- | --- | --- | --- | --- | --- | --- |
| PH-001 | R-001 | No existe seguimiento confiable del estado de los pagos | Dónde se registra, quién actualiza, quién consulta y qué falló ese día | Baja | En duda | M-001 |
| PH-002 | R-001 | La información existe, pero no estaba accesible para quien la necesitaba | Roles, permisos y momento de consulta | Baja | En duda | M-002 |
| PH-003 | R-001 | La actualización o conciliación de pagos ocurre tarde | Frecuencia y responsable de actualización | Baja | En duda | M-003 |

Una anécdota puede producir varias hipótesis. No se elige una solo porque parezca probable.

## Análisis

Para cada relato se investiga:

| Dimensión | Pregunta |
| --- | --- |
| Situación | ¿Qué ocurrió exactamente y en qué contexto? |
| Expectativa | ¿Qué debía haber ocurrido? |
| Afectados | ¿Quién tuvo el problema y quién recibió la consecuencia? |
| Frecuencia | ¿Fue aislado, recurrente o permanente? |
| Impacto | ¿Qué tiempo, dinero, riesgo o retrabajo produjo? |
| Proceso actual | ¿Cómo se registra, consulta y corrige hoy? |
| Propiedad | ¿Quién es responsable de mantener la información correcta? |
| Evidencia | ¿Existe registro del caso o solo recuerdo de la conversación? |

## Confirmados

| ID | Problema confirmado | Relatos | Afectados | Frecuencia | Impacto | Causa conocida | Decisión |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PC-001 |  | R-001 |  |  |  |  | D-001 |

## Relación

Un problema confirmado puede originar varios requisitos. Un requisito no debe existir únicamente porque alguien propuso una función.

`Relato → Hipótesis → Duda en memoria → Problema confirmado → Requisito`
