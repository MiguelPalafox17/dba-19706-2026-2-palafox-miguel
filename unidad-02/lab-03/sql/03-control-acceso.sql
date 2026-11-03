--GENERAMOS EL ROL DE ANALISTA
CREATE ROLE analista NOLOGIN;

--CREAMOS UNA VISTA PARA LOS DE ANALITICA
CREATE VIEW v_analitica_clientes AS SELECT  ciudad, CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más' END AS rango_edad FROM clientes;

--DAMOS ACCESO AL SQUEMA
GRANT USAGE ON SCHEMA public TO analista;

--DAMOS PERMISO A CIERTAS OPERACIONES
GRANT SELECT ON v_analitica_clientes TO analista;

--MOSTRAMOS QUE PRIVILEGIOS TIENEN Y QUE TABLA
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants
WHERE grantee = 'analista';