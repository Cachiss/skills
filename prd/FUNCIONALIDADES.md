# Descubrimiento funcional

Este archivo sirve para preguntar qué capacidades requiere el proyecto. Es una guía de investigación, no una lista de funciones que deban construirse.

Cada capacidad debe responder a un problema confirmado o a una necesidad operativa verificable. Que una función sea común en otros productos no demuestra que sea necesaria aquí.

## Matriz

| ID | Área | Pregunta | Problema | Evidencia | Respuesta provisional | Capacidad candidata | Actores | Estado | Memoria |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CF-001 |  |  | PH-001 | E-001 |  |  |  | En duda | M-001 |

## Información principal

- ¿Qué elementos necesita registrar, consultar o controlar el proyecto?
- ¿Qué identifica de manera única a cada elemento?
- ¿Qué datos son obligatorios, opcionales, calculados o derivados?
- ¿Quién origina la información y quién confirma que es correcta?
- ¿Cuál es su ciclo de vida y qué estados puede tener?
- ¿Se archiva, cancela o elimina? ¿Puede recuperarse?
- ¿Se necesita historial de cambios, versiones o comprobantes?

## Acciones

- ¿Qué se necesita crear, ver, editar, aprobar, rechazar, cancelar o eliminar?
- ¿Qué acciones se realizan individualmente y cuáles de forma masiva?
- ¿Qué acción necesita confirmación o puede revertirse?
- ¿Qué reglas deben cumplirse antes de ejecutar cada acción?
- ¿Qué resultado y evidencia debe producir una acción exitosa?
- ¿Qué ocurre si la acción falla o queda incompleta?

## Estados y flujo

- ¿Qué estados representan el proceso real?
- ¿Quién puede mover un elemento entre estados?
- ¿Qué transiciones son válidas o están prohibidas?
- ¿Hay borradores, revisiones, aprobaciones o reaperturas?
- ¿Existen vencimientos, bloqueos, escalaciones o tareas programadas?
- ¿Cómo se detecta que algo está detenido o atrasado?

## Consulta

- ¿Qué información debe encontrarse con rapidez?
- ¿Se necesita búsqueda, filtros, ordenamiento, agrupación o vistas guardadas?
- ¿Qué datos deben aparecer en listas y cuáles en el detalle?
- ¿Se necesita paginación, navegación entre registros o acceso reciente?
- ¿Qué información debe resumirse en un tablero?
- ¿Qué consultas actuales son difíciles o dependen de recordar datos?

## Actores y permisos

Investigar esta sección solo cuando varias personas participen o el acceso deba diferenciarse.

- ¿Quién necesita ejecutar cada acción?
- ¿Todos pueden ver la misma información?
- ¿Quién captura, corrige, aprueba, elimina, exporta o administra?
- ¿El acceso se limita al registro propio, proyecto, equipo u organización?
- ¿Una persona puede tener varios roles o delegar temporalmente?
- ¿Qué ocurre al retirar un acceso o cambiar una responsabilidad?
- ¿Se necesita registrar quién hizo cada cambio?

## Colaboración

- ¿Se necesitan responsables, asignaciones o participantes?
- ¿Se requieren comentarios, menciones, notas internas o archivos adjuntos?
- ¿Cómo se evita que dos personas sobrescriban cambios?
- ¿Quién necesita enterarse de una actualización?
- ¿Qué conversaciones deben quedar asociadas al registro y cuáles no?

## Notificaciones

- ¿Qué evento requiere aviso y cuál no?
- ¿A quién se notifica, por qué canal y con qué urgencia?
- ¿El aviso debe ser inmediato, agrupado o programado?
- ¿Puede configurarse o silenciarse?
- ¿Qué ocurre si el canal falla?
- ¿Se necesita evidencia de entrega o lectura?

## Archivos

- ¿Se necesitan adjuntos, imágenes, contratos o comprobantes?
- ¿Qué formatos y tamaños deben admitirse?
- ¿Se requiere vista previa, descarga, reemplazo o versionado?
- ¿Quién puede acceder, compartir o eliminar un archivo?
- ¿Cuánto tiempo debe conservarse?
- ¿Se necesita detectar duplicados o archivos dañinos?

## Importación y exportación

- ¿Qué información existente debe importarse y desde qué formato?
- ¿Cómo se mapearán, validarán y corregirán los datos?
- ¿Se necesita una vista previa antes de importar?
- ¿Qué se exporta, para quién y en qué formato?
- ¿La exportación debe respetar filtros y permisos?
- ¿Se necesita procesamiento masivo o en segundo plano?

## Integraciones

- ¿Qué sistema produce o consume la información?
- ¿La sincronización es manual, programada o en tiempo real?
- ¿Cuál sistema es la fuente de verdad?
- ¿Cómo se identifican duplicados o conflictos?
- ¿Qué ocurre si una integración no está disponible?
- ¿Se necesita reintento, conciliación y trazabilidad?

## Reportes

- ¿Qué decisión permite tomar cada reporte?
- ¿Qué métricas, dimensiones y periodos necesita?
- ¿Los datos deben ser actuales o aceptan retraso?
- ¿Se requieren totales, comparaciones, tendencias o desglose?
- ¿Quién puede verlo, descargarlo o programarlo?
- ¿Cómo se comprueba que coincide con la fuente de verdad?

## Administración

- ¿Qué configuraciones deben poder cambiarse sin desarrollar código?
- ¿Quién administra catálogos, reglas, plantillas y permisos?
- ¿Se necesita activar o desactivar funciones?
- ¿Qué cambios requieren confirmación o auditoría?
- ¿Cómo se evita una configuración inválida?

## Acceso

- ¿Se requiere cuenta, invitación o acceso público?
- ¿Cómo se inicia sesión y se recupera el acceso?
- ¿Se necesita autenticación multifactor o inicio de sesión empresarial?
- ¿Cómo expiran sesiones y se bloquean intentos sospechosos?
- ¿Qué ocurre con cuentas duplicadas, suspendidas o eliminadas?

## Errores y recuperación

- ¿Qué errores puede cometer una persona y cómo se previenen?
- ¿Qué debe validarse antes de guardar?
- ¿Puede deshacerse una acción?
- ¿Cómo se recupera trabajo no guardado?
- ¿Qué mensaje permite entender y corregir el problema?
- ¿Quién atiende fallas que una persona no puede resolver?

## Operación

- ¿Qué actividad necesita auditoría?
- ¿Qué eventos deben monitorearse?
- ¿Quién recibe alertas operativas?
- ¿Qué tareas requieren respaldo, conciliación o mantenimiento?
- ¿Qué datos deben conservarse o eliminarse por política?
- ¿Cómo se ofrece soporte y se diagnostican incidentes?

## Ejemplo

Relato: “No recordaban si habían pagado al maestro de obra.”

No se concluye automáticamente que hace falta un módulo de pagos. Primero se pregunta:

1. ¿Dónde se registra actualmente un pago y quién lo registra?
2. ¿Qué estados existen: pendiente, autorizado, pagado, rechazado o cancelado?
3. ¿Quién necesita consultar, confirmar o corregir el estado?
4. ¿Qué comprobante demuestra que el pago ocurrió?
5. ¿El caso fue aislado o sucede con frecuencia?

Según las respuestas podrían investigarse capacidades de registro, estados, responsables, comprobantes, búsqueda, alertas, conciliación o auditoría. Todas permanecen como candidatas hasta ser confirmadas por la autoridad final.
