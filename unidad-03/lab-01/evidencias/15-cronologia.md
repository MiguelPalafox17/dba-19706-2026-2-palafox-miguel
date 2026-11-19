# Actividad 17 — Reconstruir la cronología y responder a Dirección

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Tabla Cronológica de Eventos Reconstruida

A partir de la correlación entre la bitácora del servidor (`bitacora-lab01.log`), las capturas históricas de las actividades y los registros de la tabla `auditoria.cambios_clientes`, se reconstruye la cronología de eventos auditables:

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente (Línea o id_evento) |
| :---: | :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| **—** | No hay registro | Desconocido | Desconocido | Datos | Se modifico el RFC de María García a `'GAMA780912XXX'`. | Sí | No hay evidencia. |
| **1** | 2026-11-16 06:57:57 | postgres | local | Configuración | Se recargaron los parámetros del servidor: `log_connections = on`, `log_disconnections = on`, `log_line_prefix` y `log_statement = 'ddl'`. | Sí | `actividad4.txt` (líneas 10–13 y 28–31) |
| **2** | 2026-11-16 07:00:59 | app_ventas | 127.0.0.1 | Acceso Fallido | Fallo de autenticación por contraseña incorrecta: `FATAL: password authentication failed for user "app_ventas"`. | No | `actividad5.txt` (línea 2) / Bitácora servidor |
| **3** | 2026-11-16 07:01:15 | Usuario_Inexistente| 127.0.0.1 | Acceso Fallido | Fallo de autenticación: `Role "Usuario_Inexistente" does not exist`. | No | `actividad5.txt` (línea 4) / Bitácora servidor |
| **4** | 2026-11-16 07:10:52 | postgres | local | Privilegio | Revocación de privilegios: `REVOKE UPDATE ON clientes FROM soporte_ana;`. | Sí | `actividad6.txt` (línea 15) |
| **5** | 2026-11-16 07:11:05 | postgres | local | Estructura | Alteración del esquema de la tabla: `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);`. | Sí | `actividad6.txt` (línea 17) |
| **6** | 2026-11-16 17:59:48 | postgres | local | Configuración | Cambio del nivel de sentencias: `parameter "log_statement" changed to "mod"`. | Sí | `actividad7.txt` (línea 28) |
| **7** | 2026-11-16 18:00:33 | app_ventas | 127.0.0.1 | Datos | Modificación de dato sensible: `UPDATE clientes SET telefono = '6679990000' WHERE id = 3`. | Sí | `actividad7.txt` (línea 29) |
| **8** | 2026-11-16 19:52:34 | app_ventas | 127.0.0.1 | Error de autorización| Intento no autorizado de borrado: `DELETE FROM clientes WHERE id = 5` (`permission denied`). | No | `actividad8.txt` (líneas 13–14) |

## Respuestas a las Preguntas de Dirección

### ¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?
- En la actividad 3 no existe ninguna evidencia la cual indique que se cambio el RFC, ya que postgres estaba con la configuracion por defecto.
- En la actividad 7  el usuario app_ventas quedo resgistrada una sentencia en la bitacora, la cual demuestra que realizo una modificacion.
- En la actividad 12 el usuario app_ventas se registro que en la tabla de auditorias el evento que se realizo.
- En la actividad 14, la bitácora del servidor registro las sentencias DDL ejecutadas por postgres para evadir el control.


### ¿Quién cambió el teléfono?

El responsable fue app_ventas, con una fecha 2026-11-16 a las 18:00:33, desde la dirección IP 127.0.0.1 utilizando app-ventas-web.  

### ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?
1. **Usuario `app_ventas`:**  
   - *Origen:* IP `127.0.0.1`.  
   - *Fallo:* Contraseña incorrecta.  
   - *Evidencia en log:* `FATAL: password authentication failed for user "app_ventas"`.
2. **Usuario `Usuario_Inexistente`:**  
   - *Origen:* IP `127.0.0.1`.  
   - *Fallo:* Intento de conexión con un rol inexistente.  
   - *Evidencia en log:* `FATAL: password authentication failed for user "Usuario_Inexistente"`.

### ¿Qué valor tenía el RFC antes de cada cambio?
- Antes del cambio de la Actividad 3, no hay ninguna evidencia.
- Antes del cambio de la Actividad 7, no hay evidencia en la bitácora, ya que la bitácora estaba en nivel mod, y únicamente registra el texto de la sentencia ejecutada (`SET rfc = 'GAMA780912XYZ'`), pero no almacena el valor anterior.
- Antes del cambio de la Actividad 12, enía el valor `'GAMA780912XXX'`, este quedo registrado en la tabla `auditoria.cambios_clientes`.
- Antes del cambio de la Actividad 14, tenía el valor **`'GAMA780912ZZZ'`, este valor quedo fijado en el evento auditado anterior, previo a que el administrador ejecutara la desactivación del disparador para imponer `'GAMA780912GHI'`.