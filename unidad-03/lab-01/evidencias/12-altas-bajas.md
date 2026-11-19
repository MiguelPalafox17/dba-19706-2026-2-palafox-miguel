# Actividad 13 — Altas y bajas

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salidas de comandos observadas

```sql
comercializadora=# INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)
VALUES ('Pedro Ruiz', 'pedro.ruiz@example.test', 'RUPE950101AAA', 30, 'Guasave', '81000');
DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';
INSERT 0 1
DELETE 1


comercializadora=# SELECT id_evento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
       valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
 id_evento | usuario_sesion |   aplicacion   | ip_cliente | operacion | id_cliente |   rfc_antes   |  rfc_despues
-----------+----------------+----------------+------------+-----------+------------+---------------+---------------
         1 | app_ventas     | app-ventas-web | 127.0.0.1  | UPDATE    |          3 | GAMA780912XXX | GAMA780912ZZZ
         2 | postgres       | psql           |            | INSERT    |         11 |               | RUPE950101AAA
         3 | postgres       | psql           |            | DELETE    |         11 | RUPE950101AAA |
(3 rows)
```

---

## Preguntas y Respuestas

### El cliente Pedro Ruiz ya no existe en clientes. ¿Dónde queda evidencia de que existió y de sus datos?
Queda preservada en la tabla de auditoría, en los registros con `id_evento = 2` (operación `INSERT`) e `id_evento = 3` (operación `DELETE`).  
En la columna `valores_despues` del evento 2 y en `valores_antes` del evento 3, se encuentra almacenado el documento completo que contiene todos los datos originales del cliente (`nombre: 'Pedro Ruiz'`, `correo: 'pedro.ruiz@example.test'`, `rfc: 'RUPE950101AAA'`, `edad: 30`, `ciudad: 'Guasave'`, `codigo_postal: '81000'`).

### ¿Por qué ip_cliente está vacía en los eventos 2 y 3?
Porque los eventos 2 y 3 fueron ejecutados por el rol administrador `postgres` directamente.

### La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?
- Conflicto que aparece: Surge una colisión directa entre el  Derecho al Olvido (privacidad y protección de datos personales) y el Principio de No Repudio e Integridad de la Auditoría.
- Quién debe resolverlo: Debe ser resuelto de manera interdisciplinaria por el DPO (Oficial de Protección de Datos), el Área Legal y el Comité de Seguridad de la Información.