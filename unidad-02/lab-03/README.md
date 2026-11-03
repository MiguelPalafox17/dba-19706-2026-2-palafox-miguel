# 26. Informe final

## 1. Introducción

Este laboratorio aborda la privacidad, el cumplimiento y el gobierno de datos en una base de datos de clientes. El problema principal es que la organización conserva y utiliza datos personales sin documentar claramente sus finalidades, permite accesos más amplios de los necesarios, entrega copias reales a desarrollo y no cuenta con una política formal de retención.

La seguridad técnica por sí sola no es suficiente: también es necesario justificar por qué se recopila cada dato, quién puede consultarlo, durante cuánto tiempo debe conservarse y cómo se atenderán los derechos de los titulares.

## 2. Inventario de datos

| Dato | Clasificación | Finalidad principal | Acceso recomendado | Retención |
|---|---|---|---|---|
| `id` | Dato personal identificador | Identificación interna y relaciones de la base | Todos los roles según necesidad | Ligado al registro |
| `nombre` | Dato personal | Identificación del cliente, atención y facturación | Atención a Clientes y Facturación | Relación comercial más plazo fiscal |
| `correo` | Dato personal | Contacto, notificaciones y envío de CFDI | Atención a Clientes y Facturación | Durante la relación comercial |
| `telefono` | Dato personal | Soporte y coordinación de entregas | Atención a Clientes y Logística | Relación comercial u orden más plazo operativo |
| `rfc` | Dato personal fiscal | Emisión de comprobantes fiscales | Exclusivamente Facturación | Plazo legal aplicable |
| `edad` | Dato personal | Estadísticas demográficas | Analítica mediante datos agregados | Solo mientras exista finalidad |
| `ciudad` | Dato personal indirecto | Logística y análisis regional | Logística, Atención y Analítica | Plazo operativo o legal |
| `codigo_postal` | Dato personal indirecto | Entrega y validación fiscal | Logística y Facturación | Plazo legal u operativo |
| `fecha_alta` | Metadato de trazabilidad | Auditoría y antigüedad de la relación | DBA, Analítica y Dirección | Según necesidad de auditoría |

## 3. Finalidades

Los datos deben utilizarse únicamente para finalidades informadas, legítimas y necesarias:

- Operar la cuenta y atender al cliente.
- Procesar pedidos, entregas y soporte.
- Emitir comprobantes fiscales cuando el cliente lo solicite.
- Generar estadísticas agregadas para la toma de decisiones.
- Realizar marketing únicamente cuando exista una finalidad secundaria informada y consentimiento u oposición gestionable.

La existencia de un dato en la base no autoriza a utilizarlo para cualquier propósito. Marketing no debe consultar directamente la tabla `clientes`, debe recibir una vista o lista filtrada que incluya únicamente a las personas autorizadas y los datos mínimos de contacto.

## 4. Minimización

El registro principal debe contener solo los datos indispensables para la operación. Pueden eliminarse o limitarse:

- `salario`, `estado_civil` y `ocupacion`, porque no tienen una finalidad comercial primaria justificada.
- `fecha_nacimiento`, si basta con registrar una confirmación de mayoría de edad.
- `edad`, que debe transformarse en rangos para análisis estadístico.
- `rfc`, únicamente cuando sea necesario emitir un comprobante fiscal.
- `direccion` completa y `codigo_postal`, solo cuando sean necesarios para entrega o facturación.

Los datos adicionales deben almacenarse de forma separada y solicitarse cuando el cliente utilice la función que los requiere. También deben aplicarse restricciones de integridad, vistas y permisos limitados.

## 5. Control de acceso

Los permisos se relacionan con las funciones de cada área y no con la totalidad de la tabla:

- **Aplicación operativa:** lectura y escritura únicamente sobre las tablas necesarias para la operación.
- **Atención a Clientes:** acceso a nombre y medios de contacto para soporte.
- **Facturación:** acceso a nombre, RFC, correo y código postal cuando sean necesarios para CFDI.
- **Logística:** acceso a teléfono, ciudad y datos necesarios para entregas.
- **Analítica:** acceso de solo lectura a vistas agregadas o seudonimizadas, sin acceso directo a la tabla operativa.
- **Auditoría:** acceso a registros de actividad, sin permisos operativos innecesarios.
- **DBA:** administración técnica controlada; las decisiones de finalidad y autorización corresponden a los responsables del negocio y privacidad.

Se deben aplicar RBAC, mínimo privilegio, vistas restringidas, permisos por columna, enmascaramiento y, cuando corresponda, seguridad a nivel de fila.

## 6. Derechos ARCO

Las solicitudes de acceso, rectificación, cancelación y oposición tienen implicaciones técnicas:

- **Acceso:** localizar todos los registros y copias relacionados con el titular y entregar una respuesta controlada.
- **Rectificación:** actualizar el dato correcto y registrar quién, cuándo y por qué realizó el cambio.
- **Cancelación:** eliminar, anonimizar o bloquear los datos en tablas, réplicas, respaldos, exportaciones y ambientes derivados, respetando las obligaciones legales de conservación.
- **Oposición:** impedir que el dato se utilice para la finalidad objetada, especialmente campañas de marketing.

Eliminar un registro de la tabla principal no garantiza que desaparezca de WAL, réplicas, respaldos, exportaciones o copias de desarrollo. Por eso se necesitan procedimientos documentados, búsquedas por identificador, bitácoras y coordinación con los responsables de cada sistema.

## 7. Retención

El periodo de conservación debe determinarse considerando:

1. La finalidad y el tiempo durante el cual el dato es necesario.
2. Las obligaciones fiscales, contractuales y regulatorias aplicables.
3. La duración de la relación comercial y posibles controversias.
4. El evento disparador que inicia el conteo, como la cancelación de la cuenta o la última factura.
5. El propietario responsable de revisar el vencimiento.
6. La acción final: eliminación, anonimización o archivado limitado.

La retención indefinida no es adecuada cuando la finalidad ya terminó. Los plazos deben automatizarse, revisarse periódicamente y aplicarse también a respaldos y ambientes no productivos.

## 8. Gobierno de datos

| Dato | Finalidad | Responsable | Usuarios Autorizados | Protección | Retención | Acción al Finalizar |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `nombre` | Operación y facturación | Gerente Comercial | Atención a Clientes, Facturación | Permisos por columna, Vistas restringidas | Duración de la relación + 5 años fiscal | Anonimización |
| `correo` | Contacto operativo | Gerente de Servicio | Atención a Clientes, Facturación | Cifrado TLS en tránsito, restricción por rol | Duración de la relación comercial | Eliminación lógica |
| `telefono` | Soporte urgente y entrega | Gerente de Logística | Atención a Clientes, Logística | Enmascaramiento | Duración de la orden + 1 año | Sobrescritura **NULL** |
| `rfc` | Emisión fiscal de CFDI | Gerente de Finanzas | Exclusivo Facturación | Cifrado de columna | 5 años | Depuración segura de tabla y respaldos |
| `edad` | Análisis de mercado | Director de Marketing | Exclusivo Analítica (Solo lectura en vista) | Vista agregada sin identificadores | Indefinido | N/A (Dato agregativo no personal) |
| `ciudad` | Logística y estrategia | Gerente de Operaciones | Logística, Analítica, Atención | Control de acceso basado en roles (RBAC) | 5 años | Purga de tablas operativas |
| `codigo_postal` | Validación fiscal | Gerente de Finanzas | Facturación, Logística | Validación de entrada / Vistas | 5 años | Purga física |

## 9. Evaluación integral

Los principales riesgos identificados son:

1. Acceso directo de Analítica a la tabla completa.
2. Conservación de datos durante 12 años sin política documentada.
3. Copias completas y reales entregadas a desarrolladores.
4. Uso de correos para marketing sin demostrar consentimiento.
5. Falta de documentación de finalidades.
6. Ausencia de auditoría sobre cambios en correo y RFC.
7. Datos fiscales expuestos en tablas de soporte.
8. Falta de segregación de funciones para el DBA.
9. Ausencia de un procedimiento técnico para solicitudes ARCO.
10. Persistencia de datos personales en respaldos históricos.

Los controles prioritarios son vistas agregadas, mínimo privilegio, anonimización de copias, retención documentada, consentimiento y exclusión para marketing, auditoría, cifrado, procedimientos ARCO y rotación segura de respaldos.

## 10. Conclusiones

Aprendí que la privacidad, la seguridad y la administración de bases de datos son responsabilidades relacionadas, pero no equivalentes. El cifrado y los permisos protegen técnicamente la información, mientras que la privacidad exige además justificar la finalidad, reducir la cantidad de datos, respetar los derechos de los titulares y eliminar la información cuando deja de ser necesaria.

Una administración responsable debe integrar inventario, control de acceso, auditoría, retención, respaldos, ambientes de desarrollo y gobierno. Las decisiones deben estar documentadas y repartidas entre las áreas técnicas, jurídicas, de privacidad y los propietarios de los datos.

# 27. Preguntas de reflexión

## 1. ¿Una base de datos técnicamente segura necesariamente cumple con todos los requisitos de privacidad?

No. Una base puede tener cifrado, firewalls y autenticación fuerte, pero incumplir privacidad si recopila datos excesivos, los usa para finalidades no informadas, los conserva indefinidamente o no permite ejercer los derechos ARCO. La seguridad protege la información; la privacidad también regula por qué, cómo y durante cuánto tiempo se trata.

## 2. ¿Por qué el principio de mínimo privilegio también contribuye a la privacidad?

Porque limita la cantidad de personas y procesos que pueden consultar datos personales. Si un usuario solo ve la información necesaria para su función, disminuyen la exposición accidental, el uso indebido y el impacto de una cuenta comprometida.

## 3. ¿Por qué el DBA no debería decidir por sí solo la finalidad del tratamiento de los datos?

La finalidad depende del negocio, del aviso de privacidad y de obligaciones legales, no solo de la estructura técnica. El DBA debe implementar controles, documentar implicaciones y escalar decisiones; la finalidad debe ser definida por el propietario del dato, privacidad y el área jurídica correspondiente.

## 4. ¿Por qué los desarrolladores no deberían recibir automáticamente copias completas de bases de datos productivas?

Las copias contienen información real que no suele ser necesaria para probar una aplicación. Entregarlas aumenta el número de repositorios, equipos y personas con acceso, y puede provocar filtraciones o incumplimientos de confidencialidad.

## 5. ¿Por qué una copia utilizada para desarrollo también puede representar un riesgo de privacidad?

Porque sigue conteniendo datos personales aunque se encuentre fuera de producción. Puede quedar almacenada en laptops, repositorios, respaldos o ambientes con controles más débiles y, además, puede compartirse con más personas de las estrictamente autorizadas.

## 6. ¿Por qué la retención debe formar parte del ciclo de vida de los datos?

Porque los datos pasan por creación, uso, almacenamiento, transferencia, respaldo y disposición. Si la retención no se define desde el inicio, la información puede permanecer en tablas y copias después de que termine su finalidad, aumentando el riesgo y el costo de una eliminación posterior.

## 7. ¿Qué relación existe entre privacidad por diseño y diseño de bases de datos?

La estructura de la base determina qué datos se recopilan, cómo se relacionan y quién puede acceder a ellos. Separar información sensible, usar campos mínimos, aplicar restricciones, vistas y roles desde el diseño incorpora la privacidad como una propiedad inicial y no como una corrección posterior.

## 8. ¿Qué controles técnicos implementarías para reducir el riesgo de exposición de datos personales?

Implementaría RBAC y mínimo privilegio, vistas agregadas, permisos por columna, RLS, cifrado en tránsito y en reposo, cifrado de columnas sensibles, enmascaramiento, auditoría de consultas y cambios, anonimización de copias de desarrollo, rotación de respaldos y procedimientos automatizados de retención y eliminación.

## 9. ¿Qué información debería conocer un DBA para responder técnicamente a una solicitud ARCO?

Debe conocer los identificadores del titular, las tablas y columnas relacionadas, las vistas, réplicas, respaldos, WAL, exportaciones, proveedores y ambientes donde puede existir una copia. También necesita conocer los plazos, restricciones legales, responsables de aprobación y evidencias que deben registrarse para acceso, rectificación, cancelación u oposición.

## 10. ¿Qué responsabilidades deberían corresponder al DBA, al responsable de privacidad, al área jurídica y al propietario de los datos?

- **DBA:** implementar permisos, cifrado, auditoría, respaldos, búsquedas y procesos técnicos de eliminación o anonimización.
- **Responsable de privacidad:** definir criterios de tratamiento, supervisar derechos ARCO, evaluar riesgos y verificar el cumplimiento.
- **Área jurídica:** interpretar leyes, contratos, obligaciones fiscales y límites de conservación.
- **Propietario de los datos:** justificar la finalidad, determinar qué información necesita el proceso, autorizar usuarios y validar los periodos de uso.