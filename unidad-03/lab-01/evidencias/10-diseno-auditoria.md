# Actividad 10 — Diseñar y crear el registro de auditoría

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Justificación del diseño de la tabla de auditoría

Tabla de correspondencia entre los campos propuestos y las preguntas de Dirección:
| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
| :--- | :--- | :--- | :--- |
| `id_evento` | `BIGSERIAL` | Identificador único y orden secuencial estricto del evento. | **No (`NOT NULL`)**: Es la clave primaria (`PRIMARY KEY`) obligatoria para referenciar cada registro. |
| `momento` | `TIMESTAMPTZ` | ¿Cuándo ocurrió la modificación? | **No (`NOT NULL`)**: Todo registro de auditoría exige una marca temporal fidedigna (`DEFAULT now()`). |
| `usuario_sesion` | `TEXT` | ¿Quién hizo el cambio? (identidad real de login). | **No (`NOT NULL`)**: Debe capturar siempre al usuario autenticado (`DEFAULT session_user`). |
| `usuario_efectivo` | `TEXT` | ¿Bajo qué privilegios se ejecutó la operación? | **No (`NOT NULL`)**: Valida el contexto de privilegios (`DEFAULT current_user`). |
| `aplicacion` | `TEXT` | ¿Desde qué aplicación o sistema se originó? | **Sí**: Si el cliente no declara `application_name`, la variable puede ser nula. |
| `ip_cliente` | `INET` | ¿Desde qué equipo o dirección de red se ejecutó? | **Sí**: Conexiones por socket local Unix no poseen dirección IP (`NULL`). |
| `operacion` | `TEXT` | ¿Qué operación se realizó (INSERT, UPDATE, DELETE)? | **No (`NOT NULL`)**: Es obligatorio documentar el tipo de evento DML (`TG_OP`). |
| `id_cliente` | `BIGINT` | ¿A qué cliente específico afectó el cambio? | **Sí**: Podría ser nulo en operaciones masivas o registros sin id, aunque habitualmente captura el `id` afectado. |
| `valores_antes` | `JSONB` | ¿Qué valor tenía el dato antes del cambio? | **Sí**: En un `INSERT` no existe estado anterior (`OLD` es nulo). |
| `valores_despues` | `JSONB` | ¿Qué valor adquirió el registro tras el cambio? | **Sí**: En un `DELETE` no existe estado posterior (`NEW` es nulo). |

## Salida del comando ejecutado

```sql
comercializadora=# CREATE SCHEMA auditoria;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;
CREATE TABLE auditoria.cambios_clientes (    id_evento        BIGSERIAL PRIMARY KEY,
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(),
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user,
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user,
    aplicacion       TEXT        DEFAULT current_setting('application_name'),
    ip_cliente       INET        DEFAULT inet_client_addr(),
    operacion        TEXT        NOT NULL,
    id_cliente       BIGINT,
    valores_antes    JSONB,
    valores_despues  JSONB
);
CREATE SCHEMA
REVOKE
CREATE TABLE
```

## Preguntas y Respuestas

### 1. ¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?
`TIMESTAMPTZ` almacena el instante absoluto normalizado internamente en UTC. Al consultarlo, se puede convertir de forma precisa a la zona horaria del cliente o investigador sin ambigüedad. Mientras que `TIMESTAMP`únicamente guarda números abstractos (año, mes, día, hora) sin asociar el huso horario.

### 2. ¿Por qué se guarda el registro completo en `JSONB` y no solo la columna que cambió?
Por la resistencia a cambios de esquema, ya que si la tabla `clientes` cambia en el futuro, la tabla de auditoría no requerira modificaciones.

### 3. La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?
- Por la clasificación del dato, ya que el RFC es un dato personal y sensible y por lo tanto, la tabla `auditoria.cambios_clientes` hereda la clasificación más alta de confidencialidad y protección de datos dentro de la empresa.