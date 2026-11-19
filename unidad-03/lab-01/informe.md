# Informe Final — LAB-01: Bitácoras y Auditoría del Dato en PostgreSQL

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16.14)  
**Alumno:** Miguel Palafox — `ma.palafox23@info.uas.edu.mx`  
**Fecha de elaboración:** 2026-11-18  

## 1. Despliegue y situación inicial

El servidor PostgreSQL 16.14 se ejecutó dentro del contenedor Docker denominado `laboratorio`. Al iniciar el laboratorio, se consultó la vista `pg_settings` para verificar el estado de los parámetros de registro:

| Parámetro | Valor inicial | Fuente |
|:---|:---|:---|
| `logging_collector` | `off` | default |
| `log_connections` | `off` | default |
| `log_disconnections` | `off` | default |
| `log_statement` | `none` | default |
| `log_line_prefix` | `%m [%p]` | default |
| `log_destination` | `stderr` | default |

Con esta configuración, el servidor no registraba quién se conectaba, no almacenaba ninguna sentencia SQL ejecutada y el prefijo de línea solo incluía la marca de tiempo y el PID del proceso, sin usuario ni dirección IP del cliente.

Dado que `logging_collector = off`, PostgreSQL enviaba la salida de diagnóstico directamente a `stderr`. El destino final de esos mensajes quedaba bajo control del motor de despliegue (Docker), no del motor de base de datos, por lo que no existían archivos de log administrados por PostgreSQL en el directorio `log/`. Esta situación hacía **imposible responder** ante una consulta de Dirección sobre quién había modificado datos sensibles: no había registro técnico que lo probara.


## 2. Configuración aplicada

Para obtener trazabilidad real, se aplicaron los siguientes cambios mediante:

```sql
ALTER SYSTEM SET logging_collector     = on;
ALTER SYSTEM SET log_connections       = on;
ALTER SYSTEM SET log_disconnections    = on;
ALTER SYSTEM SET log_line_prefix       = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement         = 'ddl';   -- luego elevado a 'mod'
SELECT pg_reload_conf();
```

### Distinción recarga vs. reinicio

| Acción | Cuándo aplica | Requiere reinicio |
|:---|:---|:---|
| `pg_reload_conf()` / `SIGHUP` | Parámetros de bajo impacto (`log_statement`, `log_connections`, prefijos) | No |
| Reinicio del contenedor | `logging_collector` (requiere que el proceso principal lo inicialice) | Sí |

La activación de logging_collector requirió un reinicio del contenedor, mientras que el resto de ajustes se aplicaron de inmediato. La vista `dba.bitacora` permitió consultar el contenido del log activo desde SQL, centralizando el acceso a la traza sin salir de la sesión de `psql`.


## 3. Eventos observados e interpretados

### 3.1 Accesos y autenticación

| Evento | Usuario | Origen | Resultado |
|:---|:---|:---|:---|
| Contraseña incorrecta | `app_ventas` | `127.0.0.1` | `FATAL: password authentication failed` |
| Rol inexistente | `Usuario_Inexistente` | `127.0.0.1` | `FATAL: role does not exist` |
| Base de datos incorrecta | `app_ventas` | `127.0.0.1` | `FATAL: database "comercial" does not exist` |
| Conexión exitosa + desconexión | `app_ventas` | `127.0.0.1` | Sesión de 73 ms registrada |

Los fallos de autenticación se registraron antes de que el motor conociera el nombre de base de datos o la aplicación del cliente, razón por la cual aparecen con `db=[unknown] app=[unknown]` en la línea de log.

### 3.2 Cambios de privilegios y estructura

Con `log_statement = 'ddl'`, quedaron registradas:

- `REVOKE UPDATE ON clientes FROM soporte_ana;`
- `GRANT SELECT ON clientes TO soporte_ana;`
- `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);`
- `CREATE ROLE soporte_ana LOGIN PASSWORD '...'`
- `DROP ROLE soporte_ana`

### 3.3 Modificaciones de datos (DML)

Al elevar `log_statement` de `'ddl'` a `'mod'`, el servidor comenzó a registrar `INSERT`, `UPDATE` y `DELETE`. Esto permitió capturar:

- `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` — de a `app_ventas` desde `127.0.0.1`.
- `UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3` — misma aplicacion, confirmado por trigger de auditoría.

### 3.4 Errores de autorización

- `app_ventas` intentó `DELETE FROM clientes WHERE id = 5` → `permission denied for table clientes`.
- `app_ventas` intentó `DROP ROLE soporte_ana` → `ERROR: role "soporte_ana" cannot be dropped because some objects depend on it`.
- `app_ventas` intentó `ALTER TABLE clientes DISABLE TRIGGER ...` → `ERROR: must be owner of table clientes`.

Todos los rechazos quedaron registrados con sentencia y usuario, confirmando que el sistema de log puede actuar como red de seguridad ante intentos de escalada de privilegios.


## 4. Auditoría del dato: diseño e implementación

### 4.1 Estructura de la tabla

Se creó el esquema `auditoria` con `REVOKE ALL ON SCHEMA auditoria FROM PUBLIC`, garantizando que solo el superusuario puede acceder directamente. La tabla `auditoria.cambios_clientes` almacena:

| Campo | Tipo | Propósito |
|:---|:---|:---|
| `id_evento` | `BIGSERIAL PK` | Orden secuencial inalterable |
| `momento` | `TIMESTAMPTZ` | Instante en UTC, sin ambigüedad de zona horaria |
| `usuario_sesion` | `TEXT NOT NULL` | Identidad real de login (`session_user`) |
| `usuario_efectivo` | `TEXT NOT NULL` | Privilegios bajo los que corrió (`current_user`) |
| `aplicacion` | `TEXT` | Nombre declarado por el cliente (falsificable) |
| `ip_cliente` | `INET` | Dirección de red (NULL en conexiones Unix) |
| `operacion` | `TEXT NOT NULL` | `INSERT`, `UPDATE` o `DELETE` (`TG_OP`) |
| `id_cliente` | `BIGINT` | Fila afectada |
| `valores_antes` | `JSONB` | Estado completo del registro antes del cambio |
| `valores_despues` | `JSONB` | Estado completo del registro después del cambio |

Guardar el registro completo en `JSONB`, asi proporciona resistencia a cambios de esquema futuros: si se agregan columnas a `clientes`, la tabla de auditoría no requiere modificación.

### 4.2 Rol de SECURITY DEFINER y session_user vs current_user

La función `auditoria.registrar_cambio_cliente()` se declaró con `SECURITY DEFINER`, lo que significa que se ejecuta con los privilegios de su propietario (`postgres`), no del invocador. Esto permitió que `app_ventas` —sin permisos sobre el esquema `auditoria`— disparara el trigger y el registro se insertara correctamente.

La distinción clave:

| Variable | Valor capturado en el lab | Significado |
|:---|:---|:---|
| `session_user` | `app_ventas` | Usuario que inició la sesión (identidad real) |
| `current_user` | `postgres` | Usuario efectivo dentro de la función DEFINER |

Por esta razón, `usuario_sesion` captura `session_user`: es la única variable que conserva la identidad original del actor incluso dentro de un contexto `SECURITY DEFINER`.

El parámetro `search_path = ''` se fijó en la función para evitar que un atacante inyecte un esquema malicioso al inicio de la ruta de búsqueda y substituya funciones del sistema.


## 5. Limitaciones identificadas

### 5.1 Lecturas (SELECT) no auditadas por log_statement = 'mod'

El analista `soporte_ana` ejecutó `SELECT nombre, rfc, telefono FROM clientes WHERE id = 3` y obtuvo datos sensibles (`GAMA780912GHI`). La consulta a `dba.bitacora` confirmó cero registros de esta lectura. Con `log_statement = 'mod'` solo se capturan modificaciones; los accesos de solo lectura son invisibles para la bitácora nativa del servidor.

**Implicación:** Un actor con privilegios de `SELECT` puede exfiltrar datos confidenciales sin dejar rastro en la bitácora estándar.

### 5.2 Volumen con FOR EACH ROW

La ejecución de `UPDATE clientes SET segmento = 'regular'` afectó 10 filas y generó 10 registros en `auditoria.cambios_clientes`. Si la tabla `clientes` tuviera un millón de registros, un `UPDATE` sin `WHERE` produciría un millón de filas de auditoría en segundos, saturando el almacenamiento, bloqueando la tabla durante toda la transacción y potencialmente provocando caídas por agotamiento de disco.

**Mitigación propuesta:** Particionar `auditoria.cambios_clientes` por rango de fechas, establecer una política de retención activa y, para operaciones masivas, sustituir `FOR EACH ROW` por `FOR EACH STATEMENT` con un resumen de la operación.

### 5.3 Capacidad de evasión del superusuario

`postgres` deshabilitó el trigger con `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes`, ejecutó `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3` y lo rehabilitó. El conteo de `auditoria.cambios_clientes` permaneció en 3, comprobando que el cambio no fue auditado por la tabla.

Sin embargo, la **bitácora del servidor** registró los tres comandos DDL bajo `user=postgres`, lo que permite detectar la evasión aunque no recuperar el valor anterior. Esta es la única red de seguridad disponible contra un administrador deshonesto, y depende de que el log no haya sido manipulado a nivel de sistema de archivos.


## 6. Riesgos de la bitácora

| Riesgo | Descripción | Mitigación |
|:---|:---|:---|
| **Contraseñas en texto plano** | `CREATE ROLE` con `PASSWORD '...'` queda literal en el log cuando `log_statement = 'ddl'`. | Usar `\password` interactivo en psql o `scram-sha-256` pre-hasheado; nunca pasar la contraseña como argumento SQL. |
| **Datos sensibles en log_statement = 'all'** | Toda sentencia `SELECT` quedaría en texto plano, exponiendo RFC, teléfono, etc., a quienes lean los archivos de log. | Mantener `log_statement = 'mod'` o usar `pgaudit` por objeto para limitar el alcance. |
| **Retención indefinida vs. privacidad** | Conservar logs por tiempo indefinido puede violar plazos de prescripción legal y principios de minimización de datos (LFPDPPP / GDPR). | Definir una política de retención (p. ej., 2 años) revisada por el DPO y el Área Jurídica, con depuración autorizada por el OSI y Auditoría Interna. |
| **Sin control sobre el superusuario** | Ni `pgaudit` ni el trigger protegen de forma confiable contra un superusuario; puede alterar el log a nivel de sistema operativo. | Separación de funciones: el DBA de producción no debe tener acceso directo al sistema de archivos del servidor; requiere aprobación de cambios y testigo de auditoría. |
| **application_name falsificable** | El cliente declara voluntariamente `application_name`; puede suplantar otra aplicación. | Usar `ip_cliente` como evidencia corroborante más confiable; implementar mutual TLS o certificados de cliente. |


## 7. Auditoría avanzada con pgaudit

`pgaudit` complementa la bitácora nativa con dos modos:

| Modo | Configuración | Qué audita |
|:---|:---|:---|
| **Sesión** (`pgaudit.log`) | `'role, ddl'` | Cambios de privilegios y DDL para cualquier usuario |
| **Objeto** (`pgaudit.role`) | Rol `auditor_datos` con `GRANT SELECT/UPDATE (rfc, telefono)` | Solo operaciones que tocan columnas vigiladas |

**Comportamiento observado:**
- `SELECT nombre, ciudad FROM clientes` → **no auditado** (ninguna columna vigilada involucrada).
- `SELECT nombre, rfc FROM clientes` → **auditado** (`rfc` bajo vigilancia).
- `SELECT * FROM clientes` → **auditado** (`*` incluye `rfc` y `telefono`).
- `UPDATE clientes SET rfc = '...'` → **auditado**.
- `UPDATE clientes SET ciudad = 'Navolato'` → **no auditado** (solo `ciudad` modificada).

Este comportamiento permite una auditoría de alta precisión con volumen de registros significativamente menor que `log_statement = 'all'`, preservando el rendimiento del servidor.

**Limitación de pgaudit con superusuarios:** Los superusuarios omiten inherentemente todas las comprobaciones de permisos del catálogo de seguridad; pgaudit no puede auditar de forma vinculante sus operaciones. Esto refuerza la necesidad de separación de funciones: el rol con privilegios de `postgres` no debe operar en producción sin supervisión concurrente de un auditor independiente.

---

## 8. Cronología reconstruida y conclusiones

### Cronología de eventos auditables

| # | Fecha/hora | Usuario | Evento | ¿Auditado? | Fuente |
|:---:|:---|:---|:---|:---:|:---|
| — | Sin registro | Desconocido | Modificación de RFC (Actividad 3) | **No** | Configuración por defecto sin log |
| 1 | 2026-11-16 06:57:57 UTC | postgres | Recarga de configuración (`log_statement = 'ddl'`) | Sí | `dba.bitacora` |
| 2 | 2026-11-16 07:00:59 UTC | app_ventas | Fallo de autenticación (contraseña incorrecta) | Sí | Bitácora servidor |
| 3 | 2026-11-16 07:01:15 UTC | Usuario_Inexistente | Fallo de autenticación (rol inexistente) | Sí | Bitácora servidor |
| 4 | 2026-11-16 07:10:52 UTC | postgres | `REVOKE UPDATE ON clientes FROM soporte_ana` | Sí | `dba.bitacora` |
| 5 | 2026-11-16 07:11:05 UTC | postgres | `ALTER TABLE clientes ADD COLUMN segmento` | Sí | `dba.bitacora` |
| 6 | 2026-11-16 17:59:48 UTC | postgres | Cambio a `log_statement = 'mod'` | Sí | `dba.bitacora` |
| 7 | 2026-11-16 18:00:33 UTC | app_ventas | `UPDATE clientes SET telefono = '6679990000'` | Sí | `dba.bitacora` |
| 8 | 2026-11-16 19:52:34 UTC | app_ventas | Intento de `DELETE FROM clientes` (denegado) | Sí | `dba.bitacora` |
| 9 | 2026-11-17 02:57:01 UTC | app_ventas | `UPDATE clientes SET rfc = 'GAMA780912ZZZ'` | Sí | `auditoria.cambios_clientes` (id_evento=1) |
| 10 | 2026-11-17 03:04:13 UTC | postgres | Deshabilitar + habilitar trigger, `UPDATE rfc = 'GAMA780912GHI'` | **Parcial** | `dba.bitacora` (DDL), no en tabla auditoría |

### Respuesta a Dirección

**¿Quién modificó el RFC?**
- **Actividad 3:** No hay evidencia técnica. La configuración por defecto no registraba ninguna sentencia. El cambio es irreconstruible.
- **Actividad 7 / Cronología #7:** `app_ventas` desde `127.0.0.1`. La bitácora registra la sentencia, pero no el valor previo.
- **Actividad 12 / Cronología #9:** `app_ventas`. La tabla `auditoria.cambios_clientes` conserva el valor anterior (`GAMA780912XXX`) y el nuevo (`GAMA780912ZZZ`), con marca temporal precisa y dirección IP.
- **Actividad 14 / Cronología #10:** `postgres`. Eludió el trigger; solo la bitácora del servidor prueba la ejecución de los DDL de deshabilitar/habilitar, pero sin el valor previo en la tabla de auditoría.

**¿Quién modificó el teléfono?**  
`app_ventas`, el 2026-11-16 a las 18:00:33 UTC, desde `127.0.0.1`, mediante la aplicación `app-ventas-web`.

**¿Hubo accesos fallidos?**  
Sí: `app_ventas` (contraseña incorrecta) y `Usuario_Inexistente` (rol inexistente), ambos desde `127.0.0.1`.

**¿Qué valor tenía el RFC antes de cada cambio?**  
- Actividad 3: sin evidencia.
- Actividad 7: sin evidencia (solo texto de sentencia en bitácora).
- Actividad 12: `'GAMA780912XXX'` → conservado en `auditoria.cambios_clientes`.
- Actividad 14: `'GAMA780912ZZZ'` → inferido del evento anterior; la modificación de `postgres` no fue capturada por el trigger.

### Conclusión general

La configuración inicial de PostgreSQL es un funcionalmente a ciega, ya que para propósitos de una auditoría, la habilitación del colector de logs, el prefijo enriquecido y el nivel `'mod'` nos permiten atribuir modificaciones de datos a un actor, momento y origen, pero no podemos recuperar valores anteriores. El complemento indispensable es un trigger de auditoría con almacenamiento en JSONB, ya que nos provee trazabilidad del antes y el después de cada cambio en columnas sensibles.

Ademas el sistema combinado de bitácora del servidor con tablas de auditorías y pgaudit, nos pueden responder con bastante evidencia técnica sólida, esto en la mayoría de las preguntas de Dirección. La desventaja resuelta ser técnicamente el superusuario, ya que su capacidad de evadir todos los controles internos solo puede ser contenida mediante procedimientos organizacionales, ya sea separación de funciones, aprobación de cambios y supervisión concurrente. Las trascienden las herramientas de base de datos.


## 9. Preguntas de reflexión
### 1. ¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?
Porque el motor de base de datos no retiene en memoria ni almacena el historial de sentencias ni los valores anteriores de las columnas. Ademas de que el concepto de auditoria es una accion preventiva la cual tiene que aplicarse desde el inicio.

### 2. ¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?
Porque ficilita que los procesos internos y vistas administrativas consulten y filtren el contenido de la bitácora directamente desde la consola `psql`. y tambien ayuda a tener una independencia del entorno ya que PostgreSQL almacena sus archivos con un estándar unificado dentro de `log_directory`, sin depender de formatos heterogéneos del sistema operativo.

### 3. ¿Por qué el prefijo de línea (`log_line_prefix`) es tan importante como el nivel de `log_statement`?
*Porque `log_line_prefix` inyecta los metadatos esenciales para la imputabilidad forense:
- `%u` (usuario/rol autenticado): Identifica **quién** ejecutó la acción.
- `%h` (dirección IP/host del cliente): Identifica **desde qué equipo** se originó la conexión.
- `%d` (base de datos objetivo): Especifica el entorno afectado.
- `%a` (nombre de la aplicación): Registra el cliente o interfaz reportado.
- `%m` y `%p` (marca de tiempo con milisegundos y PID): Permiten correlacionar eventos de una misma sesión en entornos con alta concurrencia.
Una línea de bitácora que registre una sentencia sin este prefijo demuestra que la operación ocurrió, pero carece de validez pericial probatoria porque no permite determinar la autoría ni el origen del acceso.

### 4. ¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?
- **Auditoría a nivel de sentencia (`log_statement = 'mod'`):** Registra el texto SQL enviado por el cliente (por ejemplo, `UPDATE clientes SET telefono = '6679990000' WHERE id = 3`).
  - *Ventajas:* Menor consumo de almacenamiento y sobrecarga moderada en el motor.
  - *Limitaciones:* No captura el valor previo de las columnas (`OLD`), impidiendo restaurar el estado original con certeza. Además, ante operaciones masivas (`UPDATE clientes SET segmento = 'regular'`), genera **una sola línea en la bitácora**, ocultando cuáles y cuántos registros fueron afectados.
- **Auditoría a nivel de dato (Disparador + tabla con `JSONB`):** Registra el impacto real fila por fila (`FOR EACH ROW`), capturando tanto el estado previo (`OLD`) como el resultante (`NEW`).
  - *Ventajas:* Trazabilidad granular total; permite comparar campo por campo mediante funciones JSON (`jsonb_each`), identificar exactamente qué datos cambiaron y formular sentencias de reversión inmediatas.