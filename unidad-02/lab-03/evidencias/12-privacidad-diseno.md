# Actividad 12 — Privacidad por diseño

Analiza el siguiente escenario:
Una nueva aplicación requiere registrar clientes.
El desarrollador propone:
```sql
CREATE TABLE clientes ( id BIGSERIAL, nombre TEXT, correo TEXT, telefono TEXT, rfc TEXT,
    edad INTEGER, direccion TEXT, ciudad TEXT, codigo_postal TEXT, fecha_nacimiento DATE,
    ocupacion TEXT,  salario NUMERIC, estado_civil TEXT, ...);
```

## Objetivo
Evaluar el diseño propuesto para el registro de clientes y aplicar los principios de minimización y privacidad por defecto desde la estructura de la base de datos.

## Procedimiento
Se revisaron los campos propuestos, sus tipos y la ausencia de restricciones. Después se identificaron los datos sin finalidad operativa clara, se solicitaron justificaciones para los campos de mayor riesgo y se propuso separar la información adicional mediante tablas, vistas y permisos limitados.


### 1. ¿Qué problemas identificas?
1. La inclusión de campos como salario, estado_civil, ocupacion y fecha_nacimiento, son campos sin un propósito operativo necesarios para una comercializadora.
2. El uso de tipos genéricos `TEXT` sin restricciones como: `NOT NULL`, formatos ni claves primarias explícitas.
3. Se asume la creencia errónea de *"guardar todo por si acaso se necesita en el futuro"*.

### 2. ¿Qué principio de privacidad se está ignorando?
Se ignora el principio de **Minimización de los Datos** y el enfoque de **Privacidad por Defecto**, los cuales exigen que la configuración inicial de cualquier base de datos limite automáticamente la recopilación al mínimo estrictamente necesario.

### 3. ¿Qué preguntas realizarías antes de aprobar el diseño?
1. ¿Cuál es la finalidad del negocio que justifique conocer el `salario` y el `estado_civil` del cliente?
2. ¿Existen obligaciones legales que requieran registrar la `fecha_nacimiento` completa en lugar de solo confirmar la mayoría de edad mediante un booleano?
3. ¿Dónde se encuentra el Aviso de Privacidad que informa al titular sobre el tratamiento de su información financiera?


### ¿Qué datos eliminarías?
* **`salario`:** Innecesario y riesgoso al constituir un dato sensible en este contexto.
* **`estado_civil`:** Irrelevante para procesos de compra, venta, facturación o soporte.
* **`ocupacion`:** Irrelevante para la relación comercial primaria.


### ¿Qué datos requerirían una justificación adicional?
* **`fecha_nacimiento`:** Si solo se requiere verificar la mayoría de edad+ no debe almacenarse la fecha exacta.
* **`direccion` completa:** Solo se justifica si la comercializadora presta servicios de entrega a domicilio.
* **`rfc`:** Solo se justifica si el cliente solicita explícitamente la emisión de un comprobante fiscal digital.

### ¿Cómo aplicarías Privacidad por Defecto?
Para aplicar **Privacidad por Defecto** en PostgreSQL:

1. La tabla principal de registro debera tener únicamente el mínimo absoluto para la cuenta (`id`, `nombre`, `correo`, `telefono`).
2. Los datos adicionales se almacenan en tablas separadas que solo se solicitan cuando el cliente decide usar dichas funciones.
3. Por defecto, el rol de la aplicación no debe tener acceso total a la tabla de datos sensibles, sino a vistas filtradas o procedimientos almacenados específicos.

## Resultado
Se recomendó eliminar `salario`, `estado_civil` y `ocupacion` del registro principal. También se determinó que `fecha_nacimiento`, `direccion` y `rfc` requieren una finalidad específica. El diseño final debe conservar solo los datos mínimos y restringir el acceso a información adicional.

## Análisis
Guardar información “por si acaso” incrementa la superficie de exposición y dificulta el cumplimiento de los derechos del titular. Además, los tipos genéricos sin restricciones pueden permitir datos incompletos o inválidos, por lo que la privacidad debe acompañarse de reglas de integridad y permisos seguros.

## Conclusión
La privacidad por diseño debe aplicarse antes de crear la tabla. Un modelo mínimo, separado por finalidad y protegido mediante vistas o procedimientos específicos reduce riesgos y facilita el cumplimiento posterior.