# Actividad 1 — Revisar la configuración de registro por defecto

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salida observada en el servidor

```sql
comercializadora=# SELECT name, setting, source FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
               'log_connections', 'log_disconnections', 'log_line_prefix',
               'log_statement', 'log_min_error_statement', 'log_timezone') ORDER BY name;
          name           |            setting             |       source
-------------------------+--------------------------------+--------------------
 log_connections         | off                            | default
 log_destination         | stderr                         | default
 log_directory           | log                            | default
 log_disconnections      | off                            | default
 log_filename            | postgresql-%Y-%m-%d_%H%M%S.log | default
 logging_collector       | off                            | default
 log_line_prefix         | %m [%p]                        | default
 log_min_error_statement | error                          | default
 log_statement           | none                           | default
 log_timezone            | Etc/UTC                        | configuration file
(10 rows)
```

## Respuestas a las Preguntas
---
### 1. Con esta configuración, ¿se registra quién se conecta?
No, porque los parámetros `log_connections` y `log_disconnections` están configurados en `off`. Por lo tanto el servidor no emite registros ni al iniciar ni al finalizar una sesión.
## 3. Interpretación
### 2. ¿Se registran las sentencias UPDATE?
No, poque el parámetro `log_statement` está en `none`, lo que significa que ninguna sentencia SQL ejecutada con éxito se escribe en la bitácora.
### 3. ¿La línea de bitácora incluye el usuario o la dirección IP del cliente?
No, ya que el formato predeterminado de `log_line_prefix` es `%m [%p]`, el cual únicamente muestra la fecha/hora con milisegundos (`%m`) y el identificador de proceso (`%p`). No incluye información de usuario (`%u`), base de datos (`%d`), aplicación (`%a`) ni dirección IP del cliente (`%h`).
### 4. ¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?
Se registran en **`Etc/UTC`** (origen `configuration file`).
### 5. Con `logging_collector = off`, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?
Lo decide el mecanismo de despliegue del servidor, ya que como PostgreSQL envía los mensajes a `stderr`, al no tener el colector activo, el motor de base de datos no crea ni administra archivos en `log_directory`.