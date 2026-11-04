-- Versión del motor
SELECT version();

-- Puerto de escucha
SHOW port;

-- Interfaces en las que el servidor acepta conexiones
SHOW listen_addresses;

-- Estado de SSL/TLS
SHOW ssl;

-- Mecanismo de cifrado de contraseñas
SHOW password_encryption;

-- Conexiones activas y sus orígenes
SELECT
    pid,
    usename,
    datname,
    client_addr,
    client_port,
    application_name,
    state,
    backend_start
FROM pg_stat_activity
ORDER BY backend_start;

-- Revisar listen_addresses
SHOW listen_addresses;


-- Revisar pg_hba.conf
SELECT
    line_number,
    type,
    database,
    user_name,
    address,
    netmask,
    auth_method,
    options
FROM pg_hba_file_rules
ORDER BY line_number;