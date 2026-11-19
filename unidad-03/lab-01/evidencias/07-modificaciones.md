# Actividad 7 — Modificaciones de datos: ddl frente a mod

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salidas de comandos observadas

### Intento de modificación con `log_statement = 'ddl'`
```powershell
PS C:\Users\HP> docker exec laboratorio psql -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3" "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora"
UPDATE 1
```

Consulta de bitácora con `log_statement = 'ddl'`:
```sql
comercializadora=# SELECT linea FROM dba.bitacora WHERE linea LIKE '%user=app_ventas%' ORDER BY num DESC LIMIT 3;
                                                                                                           linea                     
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-16 17:58:06.701 UTC [48] user=app_ventas db=comercializadora app=psql client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.100 user=app_ventas database=comercializadora host=127.0.0.1 port=59160
 2026-11-16 17:58:06.615 UTC [48] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercializadora application_name=psql
 2026-11-16 17:58:06.615 UTC [48] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="app_ventas" method=scram-sha-256 (/var/lib/postgresql/data/pg_hba.conf:119)
(3 rows)
```

### Cambio a `log_statement = 'mod'` y ejecución combinada
```powershell
PS C:\Users\HP> docker exec laboratorio psql -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3" "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora"
UPDATE 1
    nombre    |      rfc
--------------+---------------
 María García | GAMA780912XYZ
(1 row)
```

Consulta de bitácora con `log_statement = 'mod'`:
```sql
comercializadora=# SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;
                                                                                  linea                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-16 17:59:38.032 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: ALTER SYSTEM SET log_statement = 'mod';
 2026-11-16 17:59:48.546 UTC [1] user= db= app= client= LOG:  parameter "log_statement" changed to "mod"
 2026-11-16 18:00:33.326 UTC [59] user=app_ventas db=comercializadora app=psql client=127.0.0.1 LOG:  statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3
(3 rows)
```

## Preguntas y Respuestas

### ¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?
- **Nivel que registraría la lectura:** Se requeriría configurar `log_statement = 'all'`, ya  que el `'mod'` solo abarca modificaciones `INSERT`, `UPDATE`, `DELETE` e ignora sentencias `SELECT`.
- **Costo en un servidor con miles de consultas por minuto:**
  1. **Consumo masivo de almacenamiento:** Los archivos log alcanzarían tamaños exorbitantes, provocando saturación del disco.
  2. **Riesgo de exposición de datos sensibles:** Cada lectura de columnas personales o confidenciales quedaría registrada en texto plano dentro de la bitácora del servidor.

### ¿Qué le falta a esta bitácora para revertir el cambio con certeza? (Lo resolverás en la Parte B.)
A la bitácora de sentencias le falta **el valor anterior del dato (`OLD`)**.  
La bitácora documenta:
```text
LOG: statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3
```
Esto muestra qué sentencia se ejecutó, el nuevo número (`'6679990000'`) y qué fila fue el blanco (`WHERE id = 3`), pero **no dice cuál era el teléfono que María García tenía antes**. Sin el valor anterior, no es posible construir un `UPDATE` que restaure el estado fiel previo de los datos. Para resolver esto se requiere una auditoría a nivel de datos mediante disparadores (triggers) y almacenamiento en JSONB (Parte B).