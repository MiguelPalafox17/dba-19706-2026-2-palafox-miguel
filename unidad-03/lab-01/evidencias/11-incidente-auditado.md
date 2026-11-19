# Evidencia 11 — El incidente auditado

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salidas de comandos observadas

### Modificación de RFC e intento de lectura de la auditoría por parte de `app_ventas`
```powershell
PS C:\Users\HP> docker exec laboratorio psql  "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"
UPDATE 1

PS C:\Users\HP> docker exec laboratorio psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora" -c "SELECT * FROM auditoria.cambios_clientes"
ERROR:  permission denied for schema auditoria
LINE 1: SELECT * FROM auditoria.cambios_clientes
                      ^
```

### Inspección de la auditoría desde la sesión de administrador
```sql
comercializadora=# SELECT id_evento, momento, usuario_sesion, usuario_efectivo, aplicacion, ip_cliente, operacion, id_cliente
FROM auditoria.cambios_clientes ORDER BY id_evento;
 id_evento |            momento            | usuario_sesion | usuario_efectivo |   aplicacion   | ip_cliente | operacion | id_cliente
-----------+-------------------------------+----------------+------------------+----------------+------------+-----------+------------
         1 | 2026-11-17 02:57:01.432741+00 | app_ventas     | postgres         | app-ventas-web | 127.0.0.1  | UPDATE    |          3
(1 row)
```

### Comparación precisa de campos modificados (antes vs después)
```sql
comercializadora=# SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
       d.key                     AS campo,
       a.valores_antes ->> d.key AS antes,
       d.value #>> '{}'          AS despues
FROM auditoria.cambios_clientes a CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE'   AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;
 id_evento |            momento            | usuario_sesion | ip_cliente | campo |     antes     |    despues
-----------+-------------------------------+----------------+------------+-------+---------------+---------------
         1 | 2026-11-17 02:57:01.432741+00 | app_ventas     | 127.0.0.1  | rfc   | GAMA780912XXX | GAMA780912ZZZ
(1 row)
```

---

## Preguntas y Respuestas

### Compara tu hipótesis de la Actividad 11 con este resultado.
Si la función no fuera `SECURITY DEFINER`, se ejecutaría con los privilegios del rol invocador (`app_ventas`). Como dicho rol no tiene permisos sobre el esquema `auditoria` ni sobre la tabla `cambios_clientes`, la operación de actualización fallaría por denegación de permisos (`permission denied for schema auditoria`) y el `UPDATE` sobre la tabla `clientes` se abortaría.

La hipótesis se comprobó plenamente. La función declarada con `SECURITY DEFINER` se ejecutó exitosamente con los privilegios de su propietario (`postgres`), permitiendo que el trigger inserte el registro de auditoría sin necesidad de otorgar a `app_ventas` ningún permiso sobre el esquema de auditoría.

### Escribe la sentencia UPDATE que restauraría el valor anterior.
Con la evidencia exacta del valor previo conservado en la columna `antes` (`GAMA780912XXX`), la sentencia SQL para restaurar el estado original del registro es:
```sql
UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3;
```

### ¿Qué columna conserva más valor para una investigación: aplicacion o ip_cliente? ¿Cuál puede falsificar el cliente con más facilidad?
- **Columna con más valor para una investigación:** **`ip_cliente`**.
- **Columna que el cliente puede falsificar con más facilidad:** **`aplicacion`, ya que es un parámetro meramente declarativo que el cliente envía voluntariamente en la cadena de conexión.