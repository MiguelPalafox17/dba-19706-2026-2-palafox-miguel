--ACTIVAMOS EL COLECTOR
ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';

--VERIFICAMOS LOS CAMBIOS
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();

--MOVIMIENTOS QUE SE REALIZARON Y QUEDARON GUARDADOS EN EL LOGFILE
SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;

--CREAMOS EL SCHEMA DE dba
CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

--GENERAMOS LA VISTA DE BITACORA
CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(
    convert_from(pg_read_binary_file(pg_current_logfile()), 'WIN1252'), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';

-- últimas 10 líneas
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;

-- líneas que contienen un texto, sin distinguir mayúsculas
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';

-- líneas que cumplen una expresión regular
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';