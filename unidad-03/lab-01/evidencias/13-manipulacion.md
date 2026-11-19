# Actividad 14 — Intentar manipular la auditoría

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)

## Salidas de comandos observadas

### Intento de manipulación desde la cuenta de la aplicación (`app_ventas`)
```powershell
PS C:\Users\HP> docker exec laboratorio psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora?application_name=app-ventas-web" -c "DELETE FROM auditoria.cambios_clientes" -c "ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes"
ERROR:  permission denied for schema auditoria
LINE 1: DELETE FROM auditoria.cambios_clientes
                    ^
ERROR:  must be owner of table clientes
```

### Modificación eludiendo el disparador desde la cuenta de administrador (`postgres`)
```sql
comercializadora=# ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
SELECT count(*) FROM auditoria.cambios_clientes;
ALTER TABLE
UPDATE 1
ALTER TABLE
 count
-------
     3
(1 row)
```

### Verificación de la bitácora del servidor
```sql
comercializadora=# SELECT linea FROM dba.bitacora
WHERE linea ~ 'statement: (ALTER TABLE clientes (DIS|EN)ABLE|UPDATE clientes SET rfc = .GAMA780912GHI)'
ORDER BY num;
                                                                                         linea                                       
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-17 03:03:27.327 UTC [259] user=app_ventas db=comercializadora app=app-ventas-web client=127.0.0.1 LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes
 2026-11-17 03:04:13.607 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
 2026-11-17 03:04:13.631 UTC [40] user=postgres db=comercializadora app=psql client=[local] LOG:  statement: ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
(3 rows)
```

---

## Preguntas y Respuestas

### ¿Qué evidencia permite detectar que hubo un cambio sin auditar?
La bitácora del servidor `dba.bitacora` combinada con el estado de los datos.  

### ¿Qué control administrativo (no técnico) reduciría este riesgo?
1. Ninguna cuenta con privilegios de superusuario debe operar directamente en bases de datos de producción sin una solicitud de cambio previamente aprobada y sin la supervisión concurrente de un segundo testigo o auditor.
2. El personal que administra la infraestructura de base de datos no debe pertenecer a la misma línea de reporte que el personal que custodia, valida y audita la seguridad de la información.
3. Configurar alertas inmediatas ante cualquier intento o ejecución de comandos que deshabiliten disparadores.

### Relaciona esta actividad con el principio de separación de funciones de la Unidad II.
En la Unidad II se estableció que ningún rol debe concentrar facultades operativas y de control sin contrapesos (Principio de Menor Privilegio y Separación de Funciones).  
Esta actividad demuestra que ningún mecanismo interno del servidor puede protegerlo contra un superusuario con control total.