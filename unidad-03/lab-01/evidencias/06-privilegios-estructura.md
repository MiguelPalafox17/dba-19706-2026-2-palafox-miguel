# Actividad 6 — Cambios de privilegios y de estructura

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salida de comandos ejecutados

```sql
comercializadora=# REVOKE UPDATE ON clientes FROM soporte_ana;
REVOKE
comercializadora=# GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
GRANT
ALTER TABLE
comercializadora=# CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
DROP ROLE rol_temporal;
CREATE ROLE
DROP ROLE
comercializadora=# SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;
   linea                                                                                                                             
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-16 07:07:12.491 UTC [181] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: ALTER USER app_ventas PASSWORD 'SCRAM-SHA-256$4096:VzQxPqxFWnaT2Mx9sULLzA==$sai5ZQ+0pIl4+vOvapvaMqJnW0rMihm0YPXvkxvqyaM=:QltPrwKeXsDypasAzRjHmj9BtAAQ/zFcaNhdSe4LlJU='
 2026-11-16 07:10:52.358 UTC [42] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;
 2026-11-16 07:11:05.328 UTC [42] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: GRANT UPDATE ON clientes TO app_ventas;
 2026-11-16 07:11:05.345 UTC [42] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
 2026-11-16 07:11:19.656 UTC [42] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
 2026-11-16 07:11:19.675 UTC [42] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: DROP ROLE rol_temporal;
(6 rows)
```

## Preguntas y Respuestas

### ¿Qué tipo de evento es cada una de las tres primeras sentencias (privilegio o estructura)?
1. `REVOKE UPDATE ON clientes FROM soporte_ana;`: **Privilegio** (DCL).
2. `GRANT UPDATE ON clientes TO app_ventas;`: **Privilegio** (DCL).
3. `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);`: **Estructura** (DDL).

### ¿Por qué `GRANT` y `REVOKE` quedan registrados con `log_statement = 'ddl'`?
Porque en PostgreSQL, el nivel `'ddl'` abarca todas las sentencias que modifican los catálogos del sistema y las definiciones de metadatos de la base de datos.

### Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relaciónalo con la gestión de secretos de la Unidad II.
- **¿Quién debería leerla?** Solamente los administradores de bases de datos (DBA) y personal de auditoría.
- **Relación con la gestión de secretos (Unidad II):**
  - Como se observa en la bitácora con la sentencia `CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';`, PostgreSQL registra la sentencia SQL tal y como fue recibida por el parser antes de procesarla, exponiendo la contraseña en texto claro.
  - Aunque posteriormente se eliminó el rol con `DROP ROLE rol_temporal;`, la contraseña **permanece escrita en el log**.
  - De acuerdo con las buenas prácticas de gestión de secretos de la Unidad II, las contraseñas nunca deben enviarse en sentencias SQL en texto claro ni quedar en bitácoras. 
  - Esto demuestra que la bitácora es en sí misma un activo que almacena secretos críticos y debe resguardarse con estrictos controles de acceso y cifrado.