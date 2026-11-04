-- Obtener rutas exactas de los archivos sensibles (ejecutar primero)
SHOW data_directory;
SHOW config_file;
SHOW hba_file;
SHOW ident_file;

-- Verificacion del estado actual (ejecutar despues de aplicar hardening)
SELECT 'listen_addresses'    AS parametro, current_setting('listen_addresses')    AS valor
UNION ALL
SELECT 'port'                           , current_setting('port')
UNION ALL
SELECT 'ssl'                            , current_setting('ssl')
UNION ALL
SELECT 'ssl_min_protocol_version'       , current_setting('ssl_min_protocol_version')
UNION ALL
SELECT 'password_encryption'            , current_setting('password_encryption')
UNION ALL
SELECT 'max_connections'                , current_setting('max_connections')
UNION ALL
SELECT 'superuser_reserved_connections' , current_setting('superuser_reserved_connections')
UNION ALL
SELECT 'statement_timeout'             , current_setting('statement_timeout')
UNION ALL
SELECT 'idle_in_transaction_session_timeout', current_setting('idle_in_transaction_session_timeout')
UNION ALL
SELECT 'log_connections'               , current_setting('log_connections')
UNION ALL
SELECT 'log_disconnections'            , current_setting('log_disconnections');

-- Estado de conexiones actuales
SELECT
    usename,
    datname,
    client_addr,
    state,
    ssl
FROM pg_stat_activity a
LEFT JOIN pg_stat_ssl s ON s.pid = a.pid
ORDER BY usename;

-- Estado de reglas de pg_hba.conf
SELECT
    line_number,
    type,
    database,
    user_name,
    address,
    netmask,
    auth_method
FROM pg_hba_file_rules
ORDER BY line_number;

-- Estado de roles y privilegios
SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolreplication
FROM pg_roles
WHERE rolcanlogin = true
ORDER BY rolname;

-- Estado de extensiones
SELECT extname, extversion FROM pg_extension ORDER BY extname;

/*
Tabla de comparacion antes/despues — Linea base de seguridad:
+----------------------------------+-------------------+--------------------+----------------------------------------+
| Control                          | Antes             | Despues            | Justificacion                          |
+----------------------------------+-------------------+--------------------+----------------------------------------+
| listen_addresses                 | *                 | 10.10.10.20        | Reducir exposicion de red              |
| pg_hba.conf                      | all/all/0.0.0.0/0 | lab_db/app_user/LAN| Principio de minimo acceso             |
| Metodo de autenticacion          | md5               | scram-sha-256      | Protocolo mas seguro disponible        |
| Usuarios administrativos         | postgres para app | dba_admin separado | Segregacion de funciones               |
| Cuentas de aplicacion            | No existian       | app_user creado    | Minimo privilegio para la aplicacion   |
| Puerto                           | 5432              | 5432               | No cambiar el puerto no es hardening   |
| TLS                              | Por verificar     | Habilitado TLSv1.2+| Cifrado del canal de comunicacion      |
| Permisos SO                      | Por verificar     | 600/700            | Proteccion de archivos sensibles       |
| Extensiones                      | Por verificar     | Solo necesarias    | Reduccion de superficie funcional      |
| statement_timeout                | 0                 | 30000 (30s)        | Prevenir consultas de larga duracion   |
| idle_in_transaction_timeout      | 0                 | 60000 (60s)        | Liberar transacciones bloqueadas       |
+----------------------------------+-------------------+--------------------+----------------------------------------+
*/


-- ============================================================
-- VERIFICACION FINAL — Lista de comprobacion ejecutable
-- ============================================================

-- 1. Verificar que listen_addresses no sea '*'
SELECT
    CASE
        WHEN current_setting('listen_addresses') = '*' THEN 'ADVERTENCIA: listen_addresses = * (expuesto en todas las interfaces)'
        ELSE 'OK: listen_addresses = ' || current_setting('listen_addresses')
    END AS verificacion_listen_addresses;

-- 2. Verificar que SSL este habilitado
SELECT
    CASE
        WHEN current_setting('ssl') = 'on' THEN 'OK: SSL habilitado'
        ELSE 'ADVERTENCIA: SSL deshabilitado - comunicaciones en texto plano'
    END AS verificacion_ssl;

-- 3. Verificar metodo de autenticacion de contrasenas
SELECT
    CASE
        WHEN current_setting('password_encryption') = 'scram-sha-256' THEN 'OK: password_encryption = scram-sha-256'
        ELSE 'ADVERTENCIA: password_encryption = ' || current_setting('password_encryption') || ' (se prefiere scram-sha-256)'
    END AS verificacion_auth;

-- 4. Verificar que no hay superusuarios innecesarios con login
SELECT
    'Roles SUPERUSER con LOGIN: ' || string_agg(rolname, ', ') AS verificacion_superusuarios
FROM pg_roles
WHERE rolsuper = true AND rolcanlogin = true;

-- 5. Verificar reglas de pg_hba.conf con rango 0.0.0.0/0
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_hba_file_rules
            WHERE address = '0.0.0.0' AND netmask = '0.0.0.0'
        )
        THEN 'ADVERTENCIA: Existe al menos una regla con 0.0.0.0/0 (red demasiado amplia)'
        ELSE 'OK: No se encontraron reglas con rango 0.0.0.0/0'
    END AS verificacion_hba;

-- 6. Verificar timeouts configurados
SELECT
    CASE
        WHEN current_setting('statement_timeout') = '0' THEN 'ADVERTENCIA: statement_timeout sin limite (0)'
        ELSE 'OK: statement_timeout = ' || current_setting('statement_timeout')
    END AS verificacion_statement_timeout;

-- 7. Verificar registro de conexiones
SELECT
    CASE
        WHEN current_setting('log_connections') = 'on' THEN 'OK: log_connections habilitado'
        ELSE 'ADVERTENCIA: log_connections = off (no se registran las conexiones)'
    END AS verificacion_log_conexiones;
