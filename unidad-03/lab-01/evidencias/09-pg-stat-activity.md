# Actividad 9 — Sesiones activas con pg_stat_activity

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

---

## Salidas de comandos observadas

### Ejecución de consulta de larga duración desde cliente de red
```powershell
PS C:\Users\HP> docker exec laboratorio psql -c "SELECT pg_sleep(90)" "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora"
 pg_sleep 
```

### Consulta concurrente a `pg_stat_activity` en la sesión de administrador
```sql
comercializadora=# SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
 pid |  usename   | application_name | client_addr |         backend_start         | state  |             query              
-----+------------+------------------+-------------+-------------------------------+--------+--------------------------------
  40 | postgres   | psql             |             | 2026-11-16 19:40:55.931885+00 | active | SELECT pid, usename, applicati
  85 | app_ventas | psql             | 127.0.0.1   | 2026-11-16 19:54:46.4368+00   | active | SELECT pg_sleep(90)
(2 rows)
```

### Búsqueda en la bitácora
```sql
comercializadora=# SELECT linea FROM dba.bitacora WHERE linea LIKE '%[85]%' ORDER BY num;
 linea 
-------
(0 rows)
```

### Verificación tras la finalización del comando
```powershell
PS C:\Users\HP> docker exec laboratorio psql -c "SELECT pg_sleep(90)" "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora"
 pg_sleep 
----------

(1 row)
```

Al repetir la consulta en `pg_stat_activity`:
```sql
comercializadora=# SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
 pid | usename  | application_name | client_addr |         backend_start         | state  |             query              
-----+----------+------------------+-------------+-------------------------------+--------+--------------------------------
  40 | postgres | psql             |             | 2026-11-16 19:40:55.931885+00 | active | SELECT pid, usename, applicati
(1 row)
```

---

## Respuestas a las Preguntas

### ¿Qué columna permite relacionar una sesión con sus líneas de bitácora?
La columna **`pid`** (*Process ID*).  
Cada proceso worker o backend que atiende a un cliente recibe un identificador numérico de proceso asignado por el sistema operativo (en nuestra ejecución fue el PID `85`). En la bitácora, el prefijo `log_line_prefix` configurado con `%p` imprime dicho identificador entre corchetes (por ejemplo, `[85]`). Esto permite correlacionar el estado observado en tiempo real en `pg_stat_activity` con todos los mensajes históricos emitidos por esa misma sesión en la bitácora.

### Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?
Únicamente la **bitácora del servidor (`dba.bitacora` / archivos en disco)**.  
La vista `pg_stat_activity` es una estructura en memoria volátil: en cuanto la consulta finaliza y el cliente cierra la conexión, la fila correspondiente desaparece inmediatamente. La bitácora del servidor, al ser persistente en disco y haber registrado la conexión (`connection authorized`) y el fin de la sesión (`disconnection: session time: ...`), es la única evidencia forense que demuestra que dicha sesión existió, quién la ejecutó, desde qué IP y cuánto tiempo duró.

### ¿Por qué `client_addr` aparece vacío en la sesión del administrador?
Porque la sesión del administrador (`postgres`) se conecta localmente mediante un **socket de dominio Unix** (`/var/run/postgresql/.s.PGSQL.5432`) o conexión local interna del contenedor, y no a través de la pila de red TCP/IP. Al no existir una conexión por interfaz de red, el campo `client_addr` es `NULL` (aparece vacío en psql y en el log se registra como `client=[local]`). Por el contrario, la sesión del cliente de red viajó por TCP/IP mediante `127.0.0.1`, por lo que su IP queda explícitamente registrada.