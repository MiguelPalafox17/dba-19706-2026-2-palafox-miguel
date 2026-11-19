# Actividad 2 — Que el servidor administre su propia bitácora

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salida observada en el servidor

```sql
comercializadora=# SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';
       name        | setting | pending_restart
-------------------+---------+-----------------
 logging_collector | on      | f
(1 row)

comercializadora=# SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
       name        | setting |       source
-------------------+---------+--------------------
 logging_collector | on      | configuration file
(1 row)

comercializadora=# SELECT pg_current_logfile();
          pg_current_logfile
--------------------------------------
 log/postgresql-2026-11-16_065112.log
(1 row)

comercializadora=# SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;
                                                                                linea                                                
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-16 06:51:12.736 UTC [1] LOG:  starting PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
 2026-11-16 06:51:12.737 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
 2026-11-16 06:51:12.737 UTC [1] LOG:  listening on IPv6 address "::", port 5432
 2026-11-16 06:51:12.745 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
 2026-11-16 06:51:12.758 UTC [31] LOG:  database system was shut down at 2026-11-16 06:51:11 UTC
 2026-11-16 06:51:12.771 UTC [1] LOG:  database system is ready to accept connections

comercializadora=# CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;
CREATE SCHEMA
REVOKE
comercializadora=# CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';
CREATE VIEW
comercializadora=# SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;
 num |                                                                                linea                                          
-----+---------------------------------------------------------------------------------------------------------------------------------------------------------------------
   6 | 2026-11-16 06:51:12.771 UTC [1] LOG:  database system is ready to accept connections
   5 | 2026-11-16 06:51:12.758 UTC [31] LOG:  database system was shut down at 2026-11-16 06:51:11 UTC
   4 | 2026-11-16 06:51:12.745 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
   3 | 2026-11-16 06:51:12.737 UTC [1] LOG:  listening on IPv6 address "::", port 5432
   2 | 2026-11-16 06:51:12.737 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
   1 | 2026-11-16 06:51:12.736 UTC [1] LOG:  starting PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(6 rows)

comercializadora=# SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';
 linea
-------
(0 rows)

comercializadora=# SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';
 linea
-------
(0 rows)
```

## Preguntas y Respuestas

### ¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?
Porque `logging_collector` es un parámetro arquitectural del motor que exige iniciar un subproceso dedicado en segundo plano y redirigir las salidas estándar de todos los procesos del postmaster desde el arranque. Mientras que `log_statement` es un parámetro de sesión que le indica a los procesos backend ya activos qué sentencias deben auditar.


### ¿Qué ventaja tiene que la bitácora se lea con SQL y no con una herramienta del sistema operativo o del contenedor? ¿Qué riesgo introduce?
Nos Permite ordenar, filtrar con cláusulas `WHERE`, usar operadores relacionales y expresiones regulares directamente mediante lenguaje SQL desde un cliente de base de datos (`psql`), sin necesidad de tener acceso.

### ¿Quién debería poder consultar `dba.bitacora`?
Solamente los **administradores de bases de datos** y personal de auditoría debidamente autorizado.