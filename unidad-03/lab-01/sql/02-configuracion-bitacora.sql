--CONFIGURAMOS LA BITACORA
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();

--VERIFICAMOS EL ORIGEN DE LOS VALORES
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

--REVISAMOS LAS ULTIMAS LINEAS DE LA BITACORA
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;