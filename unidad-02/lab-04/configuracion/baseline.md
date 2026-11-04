# Baseline de Seguridad — PostgreSQL 16
## LAB-04 Hardening y configuración segura de PostgreSQL

**Fecha de elaboración:** 2026-11-02  
**Elaborado por:** [Nombre del estudiante]  
**Entorno:** Laboratorio académico — PostgreSQL 16  

---

## 1. Red

| Parámetro | Valor configurado | Justificación |
|-----------|-------------------|---------------|
| `listen_addresses` | `10.10.10.20` (IP de la red interna) | El servidor solo debe escuchar en la interfaz de red necesaria. `*` expone el servidor en todas las interfaces incluyendo las públicas. |
| Puerto | `5432` | Puerto estándar de PostgreSQL. No cambiarlo no constituye hardening, pero si se cambia debe documentarse. |
| Firewall | Solo 10.10.10.0/24 → 5432 | Solo la red DBA y la red de la aplicación tienen acceso al puerto. |
| Redes permitidas (pg_hba) | `10.10.10.0/24` | La red de aplicación. Ninguna otra red tiene acceso. |

### Reglas de firewall diseñadas

| Origen | Destino | Puerto | Acción |
|--------|---------|--------|--------|
| 10.10.10.0/24 (Red DBA / App) | PostgreSQL (10.10.10.20) | 5432 TCP | Permitir |
| 127.0.0.1 | PostgreSQL (10.10.10.20) | 5432 TCP | Permitir |
| Cualquier otro origen | PostgreSQL (10.10.10.20) | 5432 TCP | Denegar |

> [!IMPORTANT]
> pg_hba.conf y el firewall NO son controles equivalentes. El firewall opera en la capa de red (antes de que el paquete llegue a PostgreSQL). pg_hba.conf opera dentro del motor PostgreSQL (después de establecida la conexión TCP). Ambos son necesarios: el firewall como primera barrera y pg_hba.conf como segunda.

---

## 2. Autenticación

| Parámetro | Valor configurado | Justificación |
|-----------|-------------------|---------------|
| `password_encryption` | `scram-sha-256` | Mecanismo más seguro disponible en PG 16. Usa desafío-respuesta: el hash nunca viaja por la red. |
| Método en pg_hba.conf | `scram-sha-256` | Todos los accesos de red deben usar este método. Nunca `trust` o `md5`. |
| Contraseñas | Mínimo 12 caracteres, complejidad alta | Reducir riesgo de fuerza bruta. |
| Cuentas administrativas | Solo para administradores humanos | `postgres` no debe usarse como cuenta de aplicación. |

### Política de credenciales

- Contraseñas con mínimo 12 caracteres
- Combinación de mayúsculas, minúsculas, números y símbolos
- Sin reutilización de contraseñas anteriores
- Rotación documentada (recomendado cada 90 días en producción)

---

## 3. Autorización

| Control | Configuración | Justificación |
|---------|---------------|---------------|
| Cuenta DBA | `dba_admin` — CREATEROLE, CREATEDB | Solo para tareas administrativas. No usada por aplicaciones. |
| Cuenta de aplicación | `app_user` — Solo SELECT/INSERT/UPDATE/DELETE en tablas específicas | Principio de mínimo privilegio. |
| Cuenta de consulta | `consulta_user` — Solo SELECT en tablas específicas | Para reportes y lectura. Sin capacidad de escritura. |
| Cuenta `postgres` | Solo para acceso local de emergencia | No debe usarse en operación normal. |

### Diseño de roles

```
postgres       → Solo acceso local, emergencia
dba_admin      → LOGIN + CREATEROLE + CREATEDB (sin SUPERUSER en operación)
app_user       → LOGIN + privilegios mínimos sobre lab_db
consulta_user  → LOGIN + SELECT en tablas específicas
```

> [!WARNING]
> Ninguna cuenta de aplicación debe tener atributo SUPERUSER. Una aplicación comprometida heredaría todos los privilegios del sistema.

---

## 4. Configuración del motor

| Parámetro | Valor configurado | Justificación |
|-----------|-------------------|---------------|
| `max_connections` | 100 | Límite apropiado para el entorno. Evita agotamiento de recursos. |
| `superuser_reserved_connections` | 3 | Reservar conexiones para administración de emergencia. |
| `statement_timeout` | `30000` (30 segundos) | Prevenir consultas de larga duración que bloqueen recursos. |
| `idle_in_transaction_session_timeout` | `60000` (60 segundos) | Liberar transacciones bloqueadas que mantienen locks. |
| `idle_session_timeout` | `300000` (5 minutos) | Cerrar sesiones inactivas que consumen memoria. |
| `log_connections` | `on` | Auditoría: registrar todas las conexiones al servidor. |
| `log_disconnections` | `on` | Auditoría: registrar todas las desconexiones. |
| `log_failed_attempts` | `on` | Detectar intentos de acceso fallidos. |

### Extensiones habilitadas

| Extensión | Versión | Necesaria | Justificación |
|-----------|---------|-----------|---------------|
| `plpgsql` | 1.0 | Sí | Requerida por el motor. No puede deshabilitarse. |
| `pg_stat_statements` | 1.10 | Según uso | Útil para monitoreo de rendimiento. Habilitar si se necesita. |
| Otras | — | Verificar | Deshabilitar extensiones no utilizadas en producción. |

---

## 5. Sistema operativo

| Control | Valor esperado | Justificación |
|---------|----------------|---------------|
| Propietario de `postgresql.conf` | `postgres` | Solo el usuario del servicio debe ser propietario. |
| Propietario de `pg_hba.conf` | `postgres` | Idem. |
| Permisos de archivos de configuración | `600` (rw-------) | Solo el propietario puede leer y escribir. Ningún otro usuario del SO. |
| Permisos del directorio de datos | `700` (rwx------) | Solo el usuario `postgres` puede acceder al directorio de datos. |
| Usuario que ejecuta PostgreSQL | `postgres` (sin privilegios de root) | El servicio no debe ejecutarse como root. |

```bash
# Verificacion esperada en Linux:
ls -l /etc/postgresql/16/main/postgresql.conf
# -rw------- 1 postgres postgres ... postgresql.conf

ls -l /etc/postgresql/16/main/pg_hba.conf
# -rw------- 1 postgres postgres ... pg_hba.conf

ls -ld /var/lib/postgresql/16/main/
# drwx------ 19 postgres postgres ... main/
```

---

## 6. Cifrado (TLS/SSL)

| Parámetro | Valor configurado | Justificación |
|-----------|-------------------|---------------|
| `ssl` | `on` | Habilitar cifrado del canal de comunicación. |
| `ssl_min_protocol_version` | `TLSv1.2` | Versiones anteriores (SSLv3, TLS 1.0, 1.1) tienen vulnerabilidades conocidas. |
| Certificado | Firmado por CA confiable | En producción, no usar certificados auto-firmados. |
| Configuración de clientes | `sslmode=require` o `verify-full` | Los clientes deben exigir TLS. |

### Protección de credenciales

- Las contraseñas no deben aparecer en código fuente, scripts ni logs
- Las credenciales de conexión deben gestionarse mediante variables de entorno o gestores de secretos
- Los archivos `.pgpass` deben tener permisos `600`

---

## 7. Mantenimiento

| Control | Frecuencia | Responsable |
|---------|-----------|-------------|
| Actualización del motor | Según disponibilidad de parches de seguridad | DBA / Equipo de infraestructura |
| Revisión de pg_hba.conf | Mensual o ante cambios de arquitectura | DBA |
| Revisión de roles y privilegios | Trimestral o ante cambios de personal | DBA |
| Revisión de logs de conexión | Semanal | DBA / Seguridad |
| Rotación de contraseñas de servicio | Semestral (o ante incidente) | DBA |
| Revisión de extensiones | Ante actualizaciones mayores | DBA |
| Backup y verificación de baseline | Trimestral | DBA |

---

## 8. Configuración de pg_hba.conf (propuesta)

```
# TYPE    DATABASE    USER         ADDRESS          METHOD
# Conexiones locales del sistema
local     all         postgres                      peer
local     all         all                           scram-sha-256

# Conexiones IPv4 desde la red de la aplicacion
host      lab_db      app_user     10.10.10.0/24    scram-sha-256

# Conexiones IPv4 desde la red DBA
host      all         dba_admin    10.10.10.0/24    scram-sha-256

# Denegacion de todo lo demas (implicita, pero se puede hacer explicita)
# host   all         all          0.0.0.0/0        reject
```

> [!CAUTION]
> No usar `trust` como método de autenticación en ninguna regla de red. No usar `0.0.0.0/0` sin justificación explícita y documentada.

---

## 9. Referencia normativa

Esta baseline está alineada con los siguientes principios y recomendaciones:

- **CIS PostgreSQL Benchmark** — Center for Internet Security
- **NIST SP 800-123** — Guide to General Server Security
- **Principio de mínimo privilegio** — Solo los permisos necesarios para la función
- **Defensa en profundidad** — Múltiples capas de control independientes
- **Secure by default** — La configuración inicial debe ser segura

---

*Documento generado como parte del LAB-04 — Hardening y configuración segura de PostgreSQL*  
*Este documento debe actualizarse cada vez que se realice un cambio de configuración relevante.*
