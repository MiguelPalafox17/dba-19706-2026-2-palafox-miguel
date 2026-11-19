# Actividad 15 — Límites: lecturas y volumen

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

---

## 1. Salidas de comandos observadas

### Lectura de datos sensibles por el analista de soporte
```powershell
PS C:\Users\HP> docker exec laboratorio psql "postgresql://soporte_ana:Soporte_Practica_2026@127.0.0.1/comercializadora" -c "SELECT nombre, rfc, telefono FROM clientes WHERE id = 3"
    nombre    |      rfc      |  telefono  
--------------+---------------+------------
 María García | GAMA780912GHI | 6679990000
(1 row)
```

### Ejecución de actualización masiva y verificación de auditoría
```sql
comercializadora=# UPDATE clientes SET segmento = 'regular';
UPDATE 10

comercializadora=# SELECT count(*) AS lineas_bitacora FROM dba.bitacora
WHERE linea LIKE '%statement: UPDATE clientes SET segmento%';
 lineas_bitacora
-----------------
               0
(1 row)

comercializadora=# SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;
 operacion | count
-----------+-------
 DELETE    |     1
 INSERT    |     1
 UPDATE    |    11
(3 rows)

comercializadora=# SELECT count(*) AS lecturas_soporte FROM dba.bitacora
WHERE linea LIKE '%user=soporte_ana%SELECT nombre, rfc%';
 lecturas_soporte
------------------
                0
(1 row)
```

---

## Preguntas y Respuestas

### Si clientes tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un UPDATE sin WHERE?
El volumen de la base de datos se multiplicaria en segundos por la creación masiva de documentos. Tambien saturaría el sistema de replicación y respaldo. y la transacción tardaría considerablemente más tiempo en completarse, manteniendo bloqueos sobre la tabla y pudiendo provocar caídas por agotamiento de espacio en disco.

### Propón quién podría autorizar la depuración de auditoria.cambios_clientes.
1. El Oficial de Seguridad de la Información.
2. El Oficial de Privacidad y Cumplimiento Legal (DPO / Área Jurídica), validando que se han cumplido los plazos legales de prescripción fiscal, laboral y mercantil.
3. El Órgano Interno de Control / Auditoría Interna.

### ¿Por qué log_statement = 'all' puede convertir la bitácora en un nuevo depósito de datos sensibles?
Porque al configurar `log_statement = 'all'`, el motor de base de datos escribe en texto plano en la bitácora **todas y cada una de las consultas que recibe el servidor**, incluyendo sentencias `SELECT`, cláusulas `WHERE`, subconsultas y filtros.  
- Consultas que lean datos confidenciales (por ejemplo, `SELECT rfc, direccion, sueldo FROM empleados WHERE rfc = '...'`) quedarán plasmadas literalmente en los archivos del sistema operativo.
- Esto provoca que datos que en la base de datos estaban restringidos mediante permisos de columnas o cifrados, pasen a residir en **texto plano** en el archivo de registro.
- Cualquier persona o proceso con privilegios de lectura sobre los archivos de log o sobre la vista `dba.bitacora` podrá acceder a toda la información sensible del negocio, violando el principio de confidencialidad y convirtiendo la bitácora en un vector crítico de fuga de información.
