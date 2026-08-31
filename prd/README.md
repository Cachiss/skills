# Sistema de PRD

Este directorio convierte conversaciones, reuniones, hojas de cálculo y documentos previos en requisitos verificables.

## Principio

Una fuente puede contener evidencia, opiniones, errores o texto generado por IA. Su existencia no demuestra que su contenido sea correcto.

El usuario solicitante es siempre la autoridad final. Ninguna fuente, documento previo, tercero o resultado de IA puede sustituir su confirmación.

Nada se incorpora al PRD como hecho o requisito hasta que tenga una fuente localizable y la confirmación de la autoridad final.

## Archivos

| Archivo | Propósito |
| --- | --- |
| `FUENTES.md` | Inventario, procedencia y nivel de confianza de cada fuente |
| `DESCUBRIMIENTO.md` | Método y banco de preguntas para investigar el proyecto |
| `PROBLEMAS.md` | Relatos, síntomas, hipótesis y problemas confirmados |
| `FUNCIONALIDADES.md` | Preguntas para descubrir capacidades necesarias y evitar omisiones comunes |
| `HERRAMIENTAS.md` | Uso actual, límites y opciones para cada herramienta existente |
| `REQUERIMIENTOS.md` | Requisitos candidatos, inferencias y contradicciones |
| `DECISIONES.md` | Respuestas y decisiones confirmadas |
| `PRD.md` | Resultado vigente y confirmado |
| `STYLE.md` | Reglas editoriales y visuales |
| `.memoria/` | Respaldo interno de dudas cuando no exista memoria persistente |
| `fuentes/` | Material original o referencias de acceso |

## Estados

| Estado | Significado |
| --- | --- |
| Observado | Aparece literalmente en una fuente localizable |
| Inferido | Interpretación todavía no confirmada |
| En duda | Existe ambigüedad, conflicto o procedencia insuficiente |
| Confirmado | La autoridad final validó significado y alcance |
| Rechazado | La autoridad final indicó que no aplica |
| Sustituido | Una decisión posterior lo reemplazó |

## Ciclo

1. Registrar la fuente sin corregirla ni completar sus vacíos.
2. Extraer afirmaciones y conservar su ubicación exacta.
3. Separar texto observado de interpretación.
4. Registrar relatos, síntomas, consecuencias e hipótesis de problema.
5. Interrogar qué capacidades serán necesarias mediante prácticas comunes de software.
6. Identificar actores, roles y permisos solo cuando una capacidad lo requiera.
7. Identificar las herramientas que participan en el flujo actual.
8. Entender su propósito, uso real, datos, límites y dependencias.
9. Evaluar si conviene conservar, configurar, formatear, integrar, migrar o reemplazar.
10. Hacer preguntas de seguimiento basadas en evidencia y prácticas comunes.
11. Crear requisitos candidatos, no requisitos finales.
12. Conservar cada ambigüedad en la memoria de trabajo.
13. Preguntar a la autoridad final.
14. Guardar la respuesta en `DECISIONES.md`.
15. Promover al PRD únicamente lo confirmado.

## Validación

La autoridad final debe participar durante todo el proceso. Las preguntas se agrupan en lotes breves de hasta cinco para mantener ritmo y contexto.

Se pregunta de inmediato cuando una duda:

- Cambia el problema, el usuario o el alcance.
- Deja sin definir un rol, responsabilidad, permiso o propietario del dato.
- Convierte una inferencia en requisito.
- Afecta prioridad, seguridad, privacidad o cumplimiento.
- Revela una contradicción entre fuentes.
- Impide escribir un criterio de aceptación comprobable.
- Depende de un documento cuya procedencia no puede verificarse.
- Supone migrar, integrar o reemplazar una herramienta existente.

Una duda no bloqueante puede permanecer abierta. Una duda que cambiaría materialmente el producto detiene la promoción del requisito afectado.

## Memoria

Las dudas no forman parte de los documentos entregables. Se mantienen en la memoria de trabajo hasta que la autoridad final las resuelva.

Cada duda conserva un identificador interno, evidencia, interpretación provisional, impacto, pregunta y condición de bloqueo. Cuando se resuelve, la conclusión confirmada pasa a `DECISIONES.md`; la conversación o especulación no se presenta como parte del PRD.

Si el entorno no ofrece memoria persistente, se usa `.memoria/dudas.md` como respaldo local excluido de Git. No se confía únicamente en el historial de conversación para conservar información entre sesiones.

## Investigación

El proceso debe ser inquisitivo, no pasivo. Una respuesta suele abrir preguntas de seguimiento sobre funcionalidades, actores, responsables, permisos, excepciones, datos, herramientas, riesgos y resultados esperados.

No se aplica un cuestionario completo de una sola vez. Se eligen las preguntas relevantes de `DESCUBRIMIENTO.md` y `FUNCIONALIDADES.md`, se presentan en lotes de hasta cinco y se profundiza según las respuestas.

Cuando una frase describe una situación concreta, se conserva el relato y se investiga antes de generalizar. Por ejemplo, “no recordaban si habían pagado al maestro de obra” puede sugerir falta de seguimiento de pagos, pero también actualización tardía, acceso insuficiente, responsabilidades confusas o información fragmentada. Todas son hipótesis hasta que la autoridad final confirme la causa y el alcance.

## Documentos previos

Los documentos heredados empiezan con confianza `No verificada`, incluso si parecen completos o autoritativos. Si contienen texto generado por IA, se registra como tal cuando se conozca.

No se intenta decidir automáticamente si una afirmación es una alucinación. Se registra la sospecha, se busca evidencia primaria y se pregunta a la autoridad final. La ausencia de evidencia se conserva como duda.

## Herramientas previas

Una herramienta existente no se considera un obstáculo ni una solución por defecto. Primero se documenta cómo se usa realmente, qué valor aporta, qué datos contiene y de qué procesos depende.

La evaluación debe considerar estas opciones sin favorecer una antes del análisis:

| Opción | Resultado |
| --- | --- |
| Conservar | Mantener el flujo actual sin cambios materiales |
| Configurar | Obtener más valor mediante funciones ya disponibles |
| Formatear | Añadir plantillas, convenciones o transformaciones de entrada y salida |
| Integrar | Conectar herramientas y reducir trabajo manual o duplicación |
| Migrar | Mover datos y operación a otra herramienta conservando continuidad |
| Reemplazar | Sustituir la herramienta cuando el valor esperado justifique el cambio |
| Retirar | Eliminarla cuando ya no cumpla una función necesaria |

No se propone una opción hasta conocer, como mínimo, usuarios, flujo actual, entradas, salidas, fuente de verdad, volumen, frecuencia, permisos, formatos, integraciones, limitaciones, costo de cambio y criterio de éxito.

El valor añadido debe expresarse como una mejora comprobable frente a la situación actual. La novedad técnica por sí sola no cuenta como valor.

## Trazabilidad

Cada requisito confirmado debe enlazar esta cadena:

`Fuente → Evidencia → Problema, capacidad o herramienta → Requisito candidato → Memoria o decisión → Requisito en PRD`

Si la cadena se rompe, el requisito vuelve a estado `En duda`.

## Privacidad

No se guardan conversaciones, transcripciones ni datos personales sin autorización. Cuando una fuente sea sensible, `fuentes/` conserva solo una referencia de acceso y los fragmentos mínimos necesarios.
