# Actividad 4 — Configurar la bitácora

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salida observada en el servidor

```sql
comercializadora=# ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
 pg_reload_conf
----------------
 t
(1 row)

comercializadora=# SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');
      name       |                 setting                 |       source       |                  sourcefile
-----------------+-----------------------------------------+--------------------+-----------------------------------------------
 log_connections | off                                     | default            |
 log_line_prefix | %m [%p] user=%u db=%d app=%a client=%h  | configuration file | /var/lib/postgresql/data/postgresql.auto.conf
 log_statement   | ddl                                     | configuration file | /var/lib/postgresql/data/postgresql.auto.conf
(3 rows)

comercializadora=# SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;
 num |                                                                                                                                               linea                                                                                                                
-----+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  13 | 2026-11-16 06:57:57.087 UTC [1] user= db= app= client= LOG:  parameter "log_statement" changed to "ddl"
  12 | 2026-11-16 06:57:57.087 UTC [1] user= db= app= client= LOG:  parameter "log_line_prefix" changed to "%m [%p] user=%u db=%d app=%a client=%h "
  11 | 2026-11-16 06:57:57.087 UTC [1] LOG:  parameter "log_disconnections" changed to "on"
  10 | 2026-11-16 06:57:57.087 UTC [1] LOG:  parameter "log_connections" changed to "on"
   9 | 2026-11-16 06:57:57.085 UTC [1] LOG:  received SIGHUP, reloading configuration files
   8 | 2026-11-16 06:56:15.427 UTC [29] LOG:  checkpoint complete: wrote 29 buffers (0.2%); 0 WAL file(s) added, 0 removed, 0 recycled; write=2.633 s, sync=0.045 s, total=2.716 s; sync files=24, longest=0.024 s, average=0.002 s; distance=108 kB, estimate=108 kB; lsn=0/19A7080, redo lsn=0/19A7048
(6 rows)
```

## Preguntas y Respuestas

### ¿Por qué el proceso que registra el cambio es el principal y no tu sesión?
Porque `pg_reload_conf()` envía la señal de sistema al proceso principal del servidor PostgreSQL. Asi que es el postmaster quien procesa la señal, relee los archivos de configuración e `postgresql.conf` y `postgresql.auto.conf`, y notifica a los procesos hijos los nuevos parámetros.

### ¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?
- Al recargar la configuración, el servidor dejaría de registrar las sentencias SQL posteriores en la bitácora.
- Sí quedaría rastro, ya que el proceso principal emite obligatoriamente a la bitácora.

### ¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?
Porque este archivo está destinado exclusivamente para la gestión automática del motor mediante sentencias `ALTER SYSTEM`. Cualquier cambio manual puede ser sobrescrito o eliminado en una ejecución posterior de `ALTER SYSTEM`. Además, introducir errores tipográficos o sintácticos directamente en el archivo puede provocar que el servidor falle al recargar o al reiniciar.