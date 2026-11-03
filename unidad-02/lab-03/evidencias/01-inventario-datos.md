# Actividad 1 — Inventario y finalidad de los datos

## Objetivo
Identificar los datos personales del sistema, justificar su uso, establecer el nivel de acceso adecuado y definir un periodo de retención proporcional a su finalidad.

## Procedimiento
Se revisó cada campo del inventario y se clasificó según su naturaleza personal, finalidad operativa, necesidad, usuarios autorizados, periodo de conservación y justificación. También se diferenciaron los datos indispensables de aquellos que solo deben utilizarse de forma agregada o restringida.

| Campo | ¿Es Dato Personal? | Finalidad | ¿Es Necesario? | Nivel de Acceso | Retención | Justificación |
| :--- | :---: | :--- | :---: | :--- | :--- | :--- |
| `id` | Sí (Identificador) | Clave primaria / Identificación interna | Sí | Todos los roles | Indefinido (ligado al registro) | Es la clave indispensable para mantener la integridad referencial y la trazabilidad del sistema |
| `nombre` | Sí | Identificación individual del cliente | Sí | Atención a Clientes, Facturación | Relación comercial + 5 años fiscal | Requerido de forma directa para dirigirse al cliente, validar su identidad en soporte y emitir comprobantes fiscales válidos. |
| `correo` | Sí | Canal de contacto operativo y envío de CFDI | Sí | Atención a Clientes, Facturación | Relación comercial + 5 años fiscal | Esencial para la autenticación de cuenta, notificaciones sobre pedidos y entrega digital de los comprobantes fiscales. |
| `telefono` | Sí | Contacto directo urgente y soporte | Sí | Atención a Clientes, Logística | Relación comercial | Canal secundario indispensable para resolver incidencias operativas de soporte o entregas en tiempo real. |
| `rfc` | Sí | Comprobación fiscal de operaciones | Sí (Solo Facturación) | Exclusivo Facturación | 5 años (Art. 30 del CFF) | Requisito legal estricto ante la autoridad tributaria (SAT) para facturar, su acceso debe restringirse a Finanzas. |
| `edad` | Sí | Análisis demográfico y perfilamiento | No en operativa diaria | Exclusivo Analítica (Agregado) | Relación comercial | Innecesaria en la operación diaria. Capturar la edad exacta violaría la minimización; solo se justifica agregada en rangos. |
| `ciudad` | Sí (Indirecto) | Logística de envíos y análisis regional | Sí | Atención a Clientes, Logística, Analítica | Relación comercial | Permite determinar la cobertura del servicio, coordinar la logística de entrega y realizar segmentaciones geográficas. |
| `codigo_postal` | Sí (Indirecto) | Validación de domicilio fiscal y entrega | Sí | Facturación, Logística | 5 años (Fiscal) / Relación comercial | Requerido normativamente para la validez de la factura electrónica y el cálculo preciso de costos de envío. |
| `fecha_alta` | No (Metadato) | Control de antigüedad y auditoría | Sí | DBA, Analítica, Dirección | Indefinido (Dato disociado) | Metadato del sistema necesario para el control de trazabilidad, métricas de retención de clientes y cómputo de caducidad. |

## Resultado
Se determinó que `nombre`, `correo`, `telefono`, `rfc`, `ciudad` y `codigo_postal` requieren controles de acceso específicos. La `edad` no es necesaria para la operación diaria y debe manejarse únicamente en rangos agregados. Además, se establecieron criterios de retención vinculados con la relación comercial y las obligaciones fiscales.

## Análisis
El inventario evidencia que no todos los datos deben estar disponibles para todos los roles. La separación por finalidad y la minimización reducen la exposición innecesaria, mientras que la retención diferenciada permite cumplir obligaciones legales sin conservar información personal indefinidamente.

## Conclusión
El inventario proporciona una base para implementar gobierno de datos, permisos por rol y políticas de ciclo de vida. Cada campo debe mantenerse solo mientras exista una finalidad válida y documentada.