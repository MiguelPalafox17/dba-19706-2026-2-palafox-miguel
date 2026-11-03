# Actividad 14 — Escenario integral

Considera la siguiente situación:
La empresa tiene una base de datos con información de 50,000 clientes.
Todos los empleados del área de analítica pueden consultar directamente la tabla clientes.
La tabla contiene nombre, correo, teléfono, RFC, edad, ciudad y código postal.
El área de analítica únicamente genera estadísticas mensuales.
Los datos se conservan desde hace 12 años.
No existe una política documentada de retención.
Los desarrolladores reciben copias completas de la base de datos para realizar pruebas.
Las copias de desarrollo contienen información real.
El área de marketing utiliza los correos electrónicos para campañas promocionales.
No existe documentación clara sobre qué finalidad corresponde a cada dato.
Identifica al menos 10 problemas o riesgos.

## Objetivo
Realizar una evaluación integral de los riesgos de privacidad, seguridad y gobierno presentes en el escenario de la base de datos de clientes, y proponer controles correctivos.

## Procedimiento
Se analizaron el acceso de usuarios, la antigüedad de los datos, las copias de producción, el uso de marketing, la documentación, la auditoría, la segregación de funciones, los derechos ARCO y los respaldos. Cada problema se relacionó con el principio afectado, el riesgo y un control concreto.

## Matriz
| # | Problema Detectado | Principio Afectado | Riesgo | Control Propuesto |
| :-: | :--- | :--- | :--- | :--- |
| 1 | Acceso directo de Analítica a la tabla completa `clientes` | Mínimo Privilegio | Exposición de datos personales (`nombre`, `rfc`, `correo`) a personal no operativo | Creación de una vista agregada `v_analitica_clientes` y revocar permisos directos a la tabla `clientes` |
| 2 | Conservación de datos por más de 12 años sin política | Retención | Sanciones por las autoridades y brecha masiva de datos obsoletos | Definir una política de retención a 5 años y un script de depuración periódica |
| 3 | Copias completas de producción entregadas a Desarrolladores | Confidencialidad y Minimización | Filtración de datos reales en redes o equipos de desarrollo desprotegidos. | Anonimización al momento de la entrega de los datos |
| 4 | Uso de correos para campañas de Marketing sin consentimiento | Limitación de Finalidad y Lealtad | Denuncias por SPAM, multas por uso no autorizado de finalidades secundarias | Actualizar el Aviso de Privacidad |
| 5 | Ausencia de documentación sobre la finalidad de cada dato | Gobierno y Transparencia | Incapacidad de justificar el tratamiento ante auditorías de autoridades | Creación y mantenimiento del Catálogo. |
| 6 | Ausencia de registros de auditoría en modificaciones de correo/RFC | Trazabilidad y Responsabilidad | Imposibilidad de verificar si un cambio fue autorizado por el titular | Habilitación disparadores (*triggers*) de auditoría. |
| 7 | Almacenamiento de datos altamente identificables en tablas de soporte | Minimización de Datos | Sobreexposición de datos fiscales en áreas de atención de tickets | *Reestructurar la tabla destinada para  **soporte** eliminando campos innecesarios |
| 8 | Inexistencia de segregación de funciones para el rol de DBA | Segregación de Funciones (SoD) | Acceso irrestricto del DBA a información confidencial del negocio | Cifrado a nivel de columna con manejo de claves fuera del alcance del DBA |
| 9 | Inexistencia de procedimiento técnico para responder a Solicitudes ARCO | Derechos de Titulares | Incumplimiento de tiempos legales para ejecutar la cancelación o rectificación | *Procedimiento operativo y scripts estandarizados de búsqueda y borrado. |
| 10 | Presistencia no controlada de datos personales en respaldos históricos | Ciclo de Vida | Restauración accidental de datos cancelados legalmente al recuperar un respaldo | Cifrado de respaldos y política estricta de rotación y destrucción de archivos de backup. |

## Resultado
Se identificaron diez problemas principales. Las medidas propuestas incluyen vistas agregadas, mínimo privilegio, retención documentada, anonimización de copias, consentimiento para marketing, catálogo de finalidades, auditoría, cifrado, procedimientos ARCO y rotación de respaldos.

## Análisis
Los riesgos están relacionados entre sí: el acceso directo y las copias reales amplifican cualquier exceso de retención o uso secundario. Por ello, no basta con corregir un permiso aislado; se necesita un programa coordinado de gobierno, seguridad, ciclo de vida y trazabilidad.

## Conclusión
La organización debe priorizar la reducción de accesos y la protección de copias, establecer una política formal de retención y documentar las finalidades. La matriz puede utilizarse como hoja de ruta para implementar controles verificables.