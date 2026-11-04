-- Listar todos los roles con sus atributos principales
SELECT
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolreplication,
    rolbypassrls,
    rolconnlimit
FROM pg_roles
ORDER BY rolname;

-- Detalle de roles con membresías (equivalente \du)
SELECT
    r.rolname                          AS rol,
    r.rolsuper                         AS superuser,
    r.rolcreaterole                    AS createrole,
    r.rolcreatedb                      AS createdb,
    r.rolcanlogin                      AS login,
    r.rolreplication                   AS replication,
    r.rolbypassrls                     AS bypassrls,
    COALESCE(
        string_agg(m.rolname, ', '), ''
    )                                  AS miembro_de
FROM pg_roles r
LEFT JOIN pg_auth_members am ON am.member = r.oid
LEFT JOIN pg_roles m        ON m.oid = am.roleid
GROUP BY r.rolname, r.rolsuper, r.rolcreaterole, r.rolcreatedb,
         r.rolcanlogin, r.rolreplication, r.rolbypassrls
ORDER BY r.rolname;
