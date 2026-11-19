# Actividad 5 — Accesos exitosos y fallidos

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Base de datos:** `comercializadora`  
**Entorno:** Contenedor Docker `laboratorio` (PostgreSQL 16)  
**Alumno:** Palafox Espinoza Miguel Angel

## Salida de comandos ejecutados

```powershell
PS C:\Users\HP> docker exec laboratorio psql -c "SELECT 1" "postgresql://app_ventas:incorrecta@127.0.0.1/comercializadora"
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "app_ventas"

PS C:\Users\HP> docker exec laboratorio psql -c "SELECT 1" "postgresql://Usuario_Inexistente:x@127.0.0.1/comercializadora"
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "Usuario_Inexistente"

PS C:\Users\HP> docker exec laboratorio psql -c "SELECT 1" "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/comercializadora"
 ?column?
----------
        1
(1 row)
```

### Consulta de bitácora registrada

```sql
comercializadora=# SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;
                                                                                                                                 linea
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-16 07:00:59.809 UTC [84] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=54682
 2026-11-16 07:00:59.811 UTC [84] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercializadora application_name=psql
 2026-11-16 07:00:59.815 UTC [84] user=app_ventas db=comercializadora app=psql client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.006 user=app_ventas database=comercializadora host=127.0.0.1 port=54682
 2026-11-16 07:02:20.327 UTC [95] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=51860
 2026-11-16 07:02:20.329 UTC [95] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercializadora application_name=psql
 2026-11-16 07:02:20.332 UTC [95] user=app_ventas db=comercializadora app=psql client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.005 user=app_ventas database=comercializadora host=127.0.0.1 port=51860
 2026-11-16 07:02:32.769 UTC [108] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=42914
 2026-11-16 07:02:32.771 UTC [108] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercializadora application_name=psql
 2026-11-16 07:02:32.776 UTC [108] user=app_ventas db=comercializadora app=psql client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.007 user=app_ventas database=comercializadora host=127.0.0.1 port=42914
 2026-11-16 07:03:05.571 UTC [117] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=44886
 2026-11-16 07:03:05.573 UTC [117] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercializadora application_name=psql
 2026-11-16 07:03:05.575 UTC [117] user=app_ventas db=comercializadora app=psql client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.004 user=app_ventas database=comercializadora host=127.0.0.1 port=44886
 2026-11-16 07:03:49.200 UTC [132] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=50448
 2026-11-16 07:03:49.202 UTC [132] user=app_ventas db=comercializadora app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercializadora application_name=psql
```

### Análisis Campo por Campo (Sección 11.1)

| Campo | Valor de ejemplo | Significado técnico |
|---|---|---|
| **Fecha y hora** | `2026-11-16 07:00:59.811 UTC` | Marca temporal con precisión de milisegundos en UTC |
| **PID** | `[84]` | Identificador del proceso que atendió la conexión |
| **Usuario** | `user=app_ventas` | Identidad del rol declarada en el protocolo de conexión |
| **Base de datos**| `db=comercializadora` | Base de datos destino solicitada |
| **Aplicación** | `app=psql` (o `app=[unknown]`) | Nombre de la aplicación cliente |
| **Cliente** | `client=127.0.0.1` | Dirección IP desde donde provino el intento |
| **Severidad** | `FATAL` / `LOG` | Nivel de gravedad del evento registrado |
| **Mensaje** | `connection authorized` / `password authentication failed` | Mensaje descriptivo del resultado |
| **Regla aplicada**| `pg_hba.conf línea 119` | Regla y método (`scram-sha-256`) evaluado para validar el acceso |

## Preguntas y Respuestas

### La bitácora registra el usuario `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?
No prueba que la aplicación de ventas legítima intentó entrar. Ya que el parámetro de usuario es un texto que cualquier cliente puede envíar de forma libre a la conexión TCP.  
**Qué prueba realmente:** Prueba que un cliente con la IP `127.0.0.1` solicitó autenticarse como `app_ventas` hacia la base de datos `comercializadora` y con una contraseña incorrecta.

### ¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?
PostgreSQL agrega en la bitácora la línea de detalle: `DETAIL: Role "Usuario_Inexistente" does not exist`.  
**Por qué no aparece en el cliente:** Para mitigar ataques de enumeración de usuarios. Por que si el servidor le indicara al cliente si el rol existe o no, un atacante remoto podría deducir qué nombres de usuario son válidos en la base de datos mediante pruebas de ensayo y error.

### ¿Por qué `app=[unknown]` en el intento fallido, pero `app=app-ventas-web` (o `app=psql`) en la desconexión?
Porque el valor de `application_name` se establece durante la parte final del protocolo de conexión, una vez que la sesión ha sido validada y autorizada exitosamente.

### ¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario.
- **Patrón sospechoso:** Múltiples registros consecutivos con severidad `FATAL: password authentication failed` concentrados en corto tiempo, provenientes de una misma dirección IP cliente hacia uno o múltiples usuarios.
- **Consulta SQL para contar intentos fallidos por usuario e IP:**
```sql
SELECT 
    substring(linea from 'user=([^\s]+)') AS usuario,
    substring(linea from 'client=([^\s]+)') AS ip_cliente,
    count(*) AS total_intentos_fallidos
FROM dba.bitacora
WHERE linea LIKE '%FATAL:  password authentication failed%'
GROUP BY usuario, ip_cliente
ORDER BY total_intentos_fallidos DESC;
```