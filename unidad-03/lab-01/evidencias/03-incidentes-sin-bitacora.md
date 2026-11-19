# Actividad 3 — El incidente sin bitácora

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Contexto y comandos ejecutados

Se ejecuta la modificación del RFC desde la cuenta de la aplicación:
```bash
docker exec laboratorio psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
# Salida: UPDATE 1
```

Al intentar buscar evidencia en la vista de bitácora como administrador:
```sql
comercializadora=# SELECT linea FROM dba.bitacora
WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';
 linea
-------
(0 rows)
```

## Preguntas y Respuestas

### ¿Puedes demostrar quién modificó el RFC?
Noa, ya que la consulta a `dba.bitacora` devuelve `0 rows`. Al tener los parámetros `log_statement = none` y `log_connections = off`, no existe ningún registro el cual documente la sesión, el usuario, la dirección IP ni la sentencia SQL que alteró el registro.

### ¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?
No, ya que al no existir registros de auditoría de conexiones ni de sentencias, existe un vacío total de evidencia. No es posible demostrar la culpabilidad ni la inocencia de ningún rol de la base de datos.

### Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?
- **¿Lo impidieron?** No, porque la operación se ejecutó correctamente y el RFC del cliente fue modificado en la base de datos.
- **¿Debían impedirlo?** No debían impedirlo si el cambio fue emitido por `app_ventas`, puesto que dicho rol tiene asignado legítimamente el privilegio sobre la tabla `clientes`.

### ¿Qué tendría que haber estado configurado antes del incidente?
1. **`logging_collector = on`** para que PostgreSQL guarde sus propios archivos de bitácora de forma persistente.
2. **`log_connections = on` y `log_disconnections = on`** para registrar el inicio, origen y fin de cada sesión.
3. **`log_statement = ''all'`** para registrar todas las sentencias de manipulación de datos.