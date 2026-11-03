# Actividad 11 — Diseñar una matriz de gobierno de datos


## Objetivo
Diseñar una matriz de gobierno que asigne responsabilidades, accesos, protecciones, periodos de retención y acciones de disposición para cada dato personal.

## Procedimiento
Se relacionó cada campo con su finalidad, propietario del dato, usuarios autorizados y medida de protección. Después se establecieron plazos de retención y acciones concretas para el vencimiento, como anonimización, eliminación lógica, sobrescritura o purga física.


### Matriz
| Dato | Finalidad | Responsable | Usuarios Autorizados | Protección | Retención | Acción al Finalizar |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `nombre` | Operación y facturación | Gerente Comercial | Atención a Clientes, Facturación | Permisos por columna, Vistas restringidas | Duración de la relación + 5 años fiscal | Anonimización |
| `correo` | Contacto operativo | Gerente de Servicio | Atención a Clientes, Facturación | Cifrado TLS en tránsito, restricción por rol | Duración de la relación comercial | Eliminación lógica |
| `telefono` | Soporte urgente y entrega | Gerente de Logística | Atención a Clientes, Logística | Enmascaramiento | Duración de la orden + 1 año | Sobrescritura **NULL** |
| `rfc` | Emisión fiscal de CFDI | Gerente de Finanzas | Exclusivo Facturación | Cifrado de columna | 5 años | Depuración segura de tabla y respaldos |
| `edad` | Análisis de mercado | Director de Marketing | Exclusivo Analítica (Solo lectura en vista) | Vista agregada sin identificadores | Indefinido | N/A (Dato agregativo no personal) |
| `ciudad` | Logística y estrategia | Gerente de Operaciones | Logística, Analítica, Atención | Control de acceso basado en roles (RBAC) | 5 años | Purga de tablas operativas |
| `codigo_postal` | Validación fiscal | Gerente de Finanzas | Facturación, Logística | Validación de entrada / Vistas | 5 años | Purga física |

## Resultado
La matriz define responsables y controles diferenciados: permisos por columna, cifrado, enmascaramiento, vistas agregadas y RBAC. También establece qué debe ocurrir cuando termina la finalidad o el plazo legal de cada dato.

## Análisis
La asignación explícita de responsabilidades evita que los permisos y plazos dependan de decisiones informales. Algunas acciones, como eliminar datos de respaldos o anonimizar información, requieren procedimientos operativos adicionales para asegurar que se cumplan en todos los repositorios.

## Conclusión
La matriz funciona como una referencia operativa para implementar gobierno de datos. Debe mantenerse actualizada cuando cambien las finalidades, roles, sistemas, obligaciones legales o periodos de retención.