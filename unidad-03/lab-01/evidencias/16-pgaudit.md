# Actividad 19 — Auditoría de objeto sobre columnas sensibles

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salidas de comandos observadas

### Configuración del rol auditor y parámetros de pgaudit
```sql
comercializadora=# CREATE ROLE auditor_datos NOLOGIN;
GRANT SELECT (rfc, telefono), UPDATE (rfc, telefono) ON clientes TO auditor_datos;
ALTER SYSTEM SET pgaudit.log = 'role, ddl';
ALTER SYSTEM SET pgaudit.role = 'auditor_datos';
ALTER SYSTEM SET pgaudit.log_relation = on;
ERROR:  role "auditor_datos" already exists
GRANT
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
comercializadora=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

### Ejecución de consultas y modificaciones por `app_ventas`
```powershell
PS C:\Users\HP> docker exec laboratorio psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora?application_name=app-ventas-web" -c "SELECT nombre, ciudad FROM clientes WHERE id = 2" -c "SELECT nombre, rfc FROM clientes WHERE id = 3" -c "SELECT * FROM clientes WHERE id = 4" -c "UPDATE clientes SET rfc = 'LOAA850315XXX' WHERE id = 1" -c "UPDATE clientes SET ciudad = 'Navolato' WHERE id = 2"
    nombre    |  ciudad  
--------------+----------
 Carlos Pérez | Navolato
(1 row)

    nombre    |      rfc      
--------------+---------------
 María García | GAMA780912GHI
(1 row)

 id |   nombre    |          correo          |  telefono  |      rfc      | edad |   ciudad   | codigo_postal | fecha_alta | segmento 
----+-------------+--------------------------+------------+---------------+------+------------+---------------+------------+----------
  4 | Luis Torres | luis.torres@example.test | 6674567890 | TOLU920201JKL |   34 | Los Mochis | 81200         | 2026-11-16 | regular
(1 row)

UPDATE 1
UPDATE 1
```

### Cambio de privilegios como administrador y verificación en la bitácora
```sql
comercializadora=# GRANT SELECT ON clientes TO soporte_ana;
SELECT linea FROM dba.bitacora WHERE linea LIKE '%AUDIT:%';
GRANT
                                                                                                                  linea              
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-19 03:07:38.163 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  AUDIT: SESSION,1,1,ROLE,GRANT,TABLE,,"GRANT SELECT (rfc, telefono), UPDATE (rfc, telefono) ON clientes TO auditor_datos;",<not logged>
 2026-11-19 03:07:38.177 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  AUDIT: SESSION,2,1,DDL,ALTER SYSTEM,,,"ALTER SYSTEM SET pgaudit.log = 'role, ddl';",<not logged>
 2026-11-19 03:07:38.186 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  AUDIT: SESSION,3,1,DDL,ALTER SYSTEM,,,ALTER SYSTEM SET pgaudit.role = 'auditor_datos';,<not logged>
 2026-11-19 03:07:38.195 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  AUDIT: SESSION,4,1,DDL,ALTER SYSTEM,,,ALTER SYSTEM SET pgaudit.log_relation = on;,<not logged>
 2026-11-19 03:08:39.133 UTC [47] user=app_ventas db=comercializadora app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,1,1,READ,SELECT,TABLE,public.clientes,"SELECT nombre, rfc FROM clientes WHERE id = 3",<not logged>
 2026-11-19 03:08:39.134 UTC [47] user=app_ventas db=comercializadora app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,2,1,READ,SELECT,TABLE,public.clientes,SELECT * FROM clientes WHERE id = 4,<not logged>
 2026-11-19 03:08:39.137 UTC [47] user=app_ventas db=comercializadora app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,3,1,WRITE,UPDATE,TABLE,public.clientes,UPDATE clientes SET rfc = 'LOAA850315XXX' WHERE id = 1,<not logged>
 2026-11-19 03:09:04.685 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  AUDIT: SESSION,5,1,ROLE,GRANT,TABLE,,GRANT SELECT ON clientes TO soporte_ana;,<not logged>
(8 rows)
```

---

## Preguntas y Respuestas

### ¿Por qué no apareció SELECT nombre, ciudad ...? ¿Por qué sí apareció SELECT * ...?
- **Por qué no apareció `SELECT nombre, ciudad FROM clientes WHERE id = 2`:**  
  Porque pgaudit está configurado en modo de auditoría de objeto utilizando el rol `auditor_datos`. Este mecanismo funciona como un filtro estricto, porque únicamente audita las consultas que leen o modifican las columnas específicas sobre las cuales dicho rol posee privilegio. Como la consulta solo solicitó las columnas `nombre` y `ciudad`, ninguna de las columnas vigiladas fue accedida, por lo que pgaudit no genera ningún registro en la bitácora.
- **Por qué sí apareció `SELECT * FROM clientes WHERE id = 4`:**  
  Porque el operador comodín `*` consulta **todas** las columnas definidas en la tabla `clientes`, las cuales incluyen las columnas vigiladas del `rfc` y `telefono`. Al detectar que la consulta accedió a columnas supervisadas por `auditor_datos`, pgaudit intercepta la sentencia y registra el evento.

### ¿Por qué no apareció UPDATE ... ciudad ...?
La sentencia ejecutada fue `UPDATE clientes SET ciudad = 'Navolato' WHERE id = 2`.  
El rol `auditor_datos` únicamente se tiene privilegios de actualización sobre las columnas vigiladas: `GRANT UPDATE (rfc, telefono) ON clientes TO auditor_datos;`.  
La sentencia modifico solamente la columna `ciudad` y evaluó la condición sobre `id`. Como no modificó ni leyó el `rfc` ni `telefono`, la operación quedó fuera del alcance de las columnas vigiladas por el rol auditor.

### ¿Qué diferencia de volumen esperarías frente a log_statement = 'all'?
**Con `log_statement = 'all'`:** El motor de base de datos escribira todas las consultas que se ejecutan en el servidor, ya sean: consultas a tablas, lecturas de tablas no sensibles y consultas repetitivas de lectura. Esto produciria grandes cantidades de registros diarios, lo que satura el almacenamiento y afecta severamente al rendimiento de entrada/salida en el disco.
2. **Con `pgaudit` en modo objeto:** La bitácora registra únicamente las sentencias que tocan datos clasificados como críticos o sensibles, ignorando el todo lo demas. Esto permite auditar con precisión el acceso a datos regulados o confidenciales sin sobrecargar la infraestructura de almacenamiento ni degradar el desempeño del servidor.

### El README oficial advierte que pgaudit no puede auditar de forma confiable a los superusuarios (REF-U3-09). ¿Qué implica para la separación de funciones?
Los superusuarios en PostgreSQL omiten de manera inherente todas las comprobaciones de permisos del catálogo de seguridad y tienen facultades para cambiar variables de sesión. Por lo tanto, ningún mecanismo interno de auditoría basado en extensiones o roles puede auditar de forma infalsificable o vinculante a un superusuario que posee control total del motor.