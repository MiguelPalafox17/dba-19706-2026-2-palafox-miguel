-- Consultar la regla actual de pg_hba.conf
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

-- Mecanismo actual de almacenamiento de contrasenas
SHOW password_encryption;

-- Listar extensiones instaladas
SELECT
    extname,
    extversion,
    extrelocatable
FROM pg_extension
ORDER BY extname;

-- Verificar en que esquema se instalaron
SELECT
    e.extname,
    e.extversion,
    n.nspname AS esquema
FROM pg_extension e
JOIN pg_namespace n ON n.oid = e.extnamespace
ORDER BY e.extname;

-- Numero maximo de conexiones
SHOW max_connections;

-- Conexiones reservadas para superusuarios
SHOW superuser_reserved_connections;

-- Tiempo maximo de ejecucion de una sentencia (0 = sin limite)
SHOW statement_timeout;

-- Tiempo maximo de una sesion inactiva dentro de una transaccion
SHOW idle_in_transaction_session_timeout;

-- Tiempo maximo de una sesion completamente inactiva (PG >= 14)
SHOW idle_session_timeout;

-- Informacion adicional de conexiones activas
SELECT
    count(*)                         AS total_conexiones,
    count(*) FILTER (WHERE state = 'active')                AS activas,
    count(*) FILTER (WHERE state = 'idle')                  AS inactivas,
    count(*) FILTER (WHERE state = 'idle in transaction')   AS idle_in_tx,
    count(*) FILTER (WHERE wait_event_type IS NOT NULL)     AS esperando
FROM pg_stat_activity;


-- Revisar TLS
-- Estado de SSL en el servidor
SHOW ssl;

-- Version minima del protocolo TLS requerida
SHOW ssl_min_protocol_version;

-- Version maxima del protocolo TLS permitida
SHOW ssl_max_protocol_version;

-- Verificar si la sesion actual usa TLS
SELECT
    pid,
    ssl,
    version,
    cipher,
    bits,
    client_dn
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();

-- Ver todas las conexiones y si usan SSL
SELECT
    s.pid,
    a.usename,
    a.datname,
    a.client_addr,
    s.ssl,
    s.version,
    s.cipher
FROM pg_stat_ssl s
JOIN pg_stat_activity a ON a.pid = s.pid
ORDER BY s.ssl DESC;