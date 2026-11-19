# Actividad 8 — Errores y operaciones rechazadas

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel


## Salidas de comandos observadas

```powershell
PS C:\Users\HP> docker exec laboratorio psql -c "DELETE FROM clientes WHERE id = 5" "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora"
ERROR:  permission denied for table clientes


comercializadora=# DROP ROLE soporte_ana;
ERROR:  role "soporte_ana" cannot be dropped because some objects depend on it
DETAIL:  privileges for table clientes

comercializadora=# SELECT linea FROM dba.bitacora
WHERE linea ~ '(ERROR|STATEMENT|DETAIL):  (permission|privileges|role|DELETE|DROP)'
ORDER BY num;
                                                                                   linea                                             
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-16 19:52:34.583 UTC [74] user=app_ventas db=comercializadora app=psql client=127.0.0.1 ERROR:  permission denied for table clientes
 2026-11-16 19:52:34.583 UTC [74] user=app_ventas db=comercializadora app=psql client=127.0.0.1 STATEMENT:  DELETE FROM clientes WHERE id = 5
 2026-11-16 19:53:14.695 UTC [40] user=postgres db=comercializadora app=psql client=[local] ERROR:  role "soporte_ana" cannot be dropped because some objects depend on it
 2026-11-16 19:53:14.695 UTC [40] user=postgres db=comercializadora app=psql client=[local] DETAIL:  privileges for table clientes
 2026-11-16 19:53:14.695 UTC [40] user=postgres db=comercializadora app=psql client=[local] STATEMENT:  DROP ROLE soporte_ana;
(5 rows)
```

---

## Preguntas y Respuestas

### ¿El intento de soporte_ana causó algún daño? ¿Por qué debe auditarse de todos modos?
- No causó ningún daño a los datos ni a la integridad de la tabla, ya que el motor abortó inmediatamente la transacción antes de modificar o eliminar fila alguna.
- **¿Por qué debe auditarse de todos modos?**
  1. Para identificar abuso de funciones o una cuenta comprometida explorando qué operaciones puede ejecutar.
  2. Permite a los desarrolladores identificar consultas mal formadas o desajustes de permisos en el software antes de que impacten a los usuarios finales.

### ¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (Actividad 5)?
- **Autenticación (Actividad 5):** Responde a la pregunta ¿Quién eres?
- **Autorización (esta actividad):** Responde a la pregunta ¿Tienes permiso para hacer esto?.

### ¿Qué indica el error de `DROP ROLE` sobre el orden correcto para dar de baja a un usuario?
Indica que PostgreSQL mantiene una integridad referencial sobre los derechos de acceso en sus catálogos internos. No permite eliminar un rol mientras existan objetos de los cuales sea propietario o privilegios vigentes concedidos a su favor sobre cualquier objeto.
