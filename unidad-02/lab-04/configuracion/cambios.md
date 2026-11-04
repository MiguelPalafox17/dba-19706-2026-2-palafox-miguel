# Registro de cambios — Hardening de PostgreSQL 16
## LAB-04

**Fecha:** 2026-11-02  
**Responsable:** [Nombre del estudiante]  
**Entorno:** Laboratorio académico — PostgreSQL 16  

---

> [!NOTE]
> Este documento registra el estado anterior y posterior a cada cambio de hardening aplicado. Todo cambio debe documentarse antes de ejecutarse, incluyendo el impacto esperado y la forma de revertirlo si es necesario.

---

## Cambio 01 — Restricción de interfaces de escucha

**Parámetro:** `listen_addresses`  
**Archivo:** `postgresql.conf`  

| Estado | Valor |
|--------|-------|
| **Antes** | `listen_addresses = '*'` |
| **Después** | `listen_addresses = 'localhost,10.10.10.20'` |

**Justificación técnica:**  
El valor `*` hace que PostgreSQL acepte conexiones en todas las interfaces de red disponibles, incluyendo interfaces públicas. Esto expone el puerto 5432 a cualquier host que pueda alcanzar cualquiera de las interfaces del servidor. La restricción a la interfaz de red privada elimina la exposición innecesaria.

**Impacto:**  
Clientes que se conectaban desde interfaces no autorizadas perderán acceso. Solo los clientes en la red `10.10.10.0/24` podrán conectarse vía TCP.

**Revert:**  
```
listen_addresses = '*'
```
Seguido de: `SELECT pg_reload_conf();` o reinicio del servicio.

**Verificación:**  
```sql
SHOW listen_addresses;
-- Resultado esperado: localhost,10.10.10.20
```
En SO: `ss -lntp | grep 5432` debe mostrar solo `10.10.10.20:5432` y `127.0.0.1:5432`.

---

## Cambio 02 — Restricción de reglas en pg_hba.conf

**Archivo:** `pg_hba.conf`  

| Estado | Regla |
|--------|-------|
| **Antes** | `host  all  all  0.0.0.0/0  scram-sha-256` |
| **Después** | `host  lab_db  app_user  10.10.10.0/24  scram-sha-256` |

**Justificación técnica:**  
La regla original permite que cualquier host en Internet intente autenticarse contra cualquier base de datos con cualquier usuario. La regla específica aplica el principio de mínimo acceso: solo la base de datos que necesita la aplicación, solo el usuario de la aplicación, solo desde la red interna de la aplicación.

**Impacto:**  
Solo `app_user` conectando desde `10.10.10.0/24` a `lab_db` podrá autenticarse por TCP. Otras combinaciones serán rechazadas.

**Revert:**  
Restaurar la línea original en `pg_hba.conf` y ejecutar `SELECT pg_reload_conf();`

**Verificación:**  
```sql
SELECT type, database, user_name, address, netmask, auth_method
FROM pg_hba_file_rules
ORDER BY line_number;
```

---

## Cambio 03 — Creación de cuentas con mínimo privilegio

**Objetos creados:**  
- `app_user` — Cuenta de aplicación con privilegios mínimos
- `consulta_user` — Cuenta de solo lectura

| Cuenta | Antes | Después |
|--------|-------|---------|
| `app_user` | No existía | LOGIN, sin SUPERUSER, SELECT/INSERT/UPDATE/DELETE en lab_db |
| `consulta_user` | No existía | LOGIN, sin SUPERUSER, SELECT en lab_db |

**Justificación técnica:**  
La aplicación no debe usar la cuenta `postgres` ni ninguna cuenta con atributos SUPERUSER. Una cuenta comprometida solo podrá ejecutar las operaciones mínimas necesarias.

**SQL ejecutado:**  
```sql
CREATE ROLE app_user WITH LOGIN PASSWORD '...' NOCREATEDB NOCREATEROLE;
CREATE ROLE consulta_user WITH LOGIN PASSWORD '...' NOCREATEDB NOCREATEROLE;

GRANT CONNECT ON DATABASE lab_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

GRANT CONNECT ON DATABASE lab_db TO consulta_user;
GRANT USAGE ON SCHEMA public TO consulta_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO consulta_user;
```

**Verificación:**  
```sql
SELECT rolname, rolsuper, rolcreaterole, rolcanlogin
FROM pg_roles
WHERE rolname IN ('app_user', 'consulta_user');
```

---

## Cambio 04 — Configuración del método de autenticación de contraseñas

**Parámetro:** `password_encryption`  
**Archivo:** `postgresql.conf`  

| Estado | Valor |
|--------|-------|
| **Antes** | `md5` |
| **Después** | `scram-sha-256` |

**Justificación técnica:**  
`md5` es un algoritmo obsoleto. En PostgreSQL con `md5`, el hash de la contraseña se transmite en la autenticación, exponiéndolo a ataques de replay. `scram-sha-256` usa un protocolo desafío-respuesta donde el hash nunca viaja por la red, y usa PBKDF2 internamente, resistente a ataques de diccionario.

**Impacto:**  
Las contraseñas existentes almacenadas con `md5` no se convierten automáticamente. Los usuarios deben cambiar su contraseña después de este cambio para que se almacene con `scram-sha-256`.

**Revert:**  
```
password_encryption = md5
```

**Verificación:**  
```sql
SHOW password_encryption;
-- Resultado esperado: scram-sha-256
```

---

## Cambio 05 — Configuración de timeouts de sesión y sentencia

**Parámetros:** `statement_timeout`, `idle_in_transaction_session_timeout`, `idle_session_timeout`  
**Archivo:** `postgresql.conf`  

| Parámetro | Antes | Después |
|-----------|-------|---------|
| `statement_timeout` | `0` (sin límite) | `30000` ms (30 seg) |
| `idle_in_transaction_session_timeout` | `0` (sin límite) | `60000` ms (60 seg) |
| `idle_session_timeout` | `0` (sin límite) | `300000` ms (5 min) |

**Justificación técnica:**  
Sesiones sin timeout consumen recursos indefinidamente. Una sesión `idle in transaction` mantiene bloqueos activos que pueden bloquear a otros usuarios. Los timeouts garantizan que los recursos se liberen oportunamente y reducen la ventana de exposición de sesiones olvidadas.

**Verificación:**  
```sql
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;
SHOW idle_session_timeout;
```

---

## Cambio 06 — Habilitación de registro de conexiones

**Parámetros:** `log_connections`, `log_disconnections`  
**Archivo:** `postgresql.conf`  

| Parámetro | Antes | Después |
|-----------|-------|---------|
| `log_connections` | `off` | `on` |
| `log_disconnections` | `off` | `on` |

**Justificación técnica:**  
Sin registro de conexiones, es imposible detectar intentos de acceso no autorizados o analizar el comportamiento de los usuarios en caso de incidente. El registro es fundamental para la auditoría y la detección de anomalías.

**Verificación:**  
```sql
SHOW log_connections;
SHOW log_disconnections;
```

---

## Cambio 07 — Habilitación de TLS

**Parámetros:** `ssl`, `ssl_min_protocol_version`  
**Archivo:** `postgresql.conf`  

| Parámetro | Antes | Después |
|-----------|-------|---------|
| `ssl` | `off` | `on` |
| `ssl_min_protocol_version` | — | `TLSv1.2` |

**Justificación técnica:**  
Sin TLS, todas las comunicaciones (incluidas las contraseñas durante la autenticación) viajan en texto plano y pueden ser interceptadas. TLS cifra el canal completo de comunicación.

**Verificación:**  
```sql
SHOW ssl;
SHOW ssl_min_protocol_version;

SELECT pid, usename, ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

---

## Resumen de cambios aplicados

| # | Control | Antes | Después | Estado |
|---|---------|-------|---------|--------|
| 01 | `listen_addresses` | `*` | `localhost,10.10.10.20` | ✅ Aplicado |
| 02 | Reglas pg_hba.conf | `all/all/0.0.0.0/0` | `lab_db/app_user/10.10.10.0/24` | ✅ Aplicado |
| 03 | Cuentas de aplicación | No existían | `app_user`, `consulta_user` creados | ✅ Aplicado |
| 04 | `password_encryption` | `md5` | `scram-sha-256` | ✅ Aplicado |
| 05 | Timeouts de sesión | Sin límite | Configurados | ✅ Aplicado |
| 06 | `log_connections` | `off` | `on` | ✅ Aplicado |
| 07 | TLS | `off` | `on` con TLSv1.2+ | ✅ Aplicado |

---

*Cada cambio debe verificarse individualmente después de aplicarse.*  
*Este documento es parte de la evidencia del LAB-04.*
