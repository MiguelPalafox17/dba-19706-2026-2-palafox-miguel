# Informe de Laboratorio — LAB-04

## 1. ¿Cuál era la principal superficie de ataque?

La principal superficie de ataque era la combinación de:

1. **`listen_addresses = '*'`** — El servidor aceptaba conexiones en todas las interfaces de red disponibles, incluyendo las públicas.
2. **Regla `host all all 0.0.0.0/0 scram-sha-256` en pg_hba.conf** — Cualquier host en Internet podía intentar autenticarse contra cualquier base de datos con cualquier usuario.

La combinación de estas dos condiciones significa que el único control era la fortaleza de las contraseñas. Si una contraseña era robada, débil o expuesta, no existía ninguna barrera de red adicional.

Adicionalmente:
- El uso de `postgres` (SUPERUSER) como cuenta de aplicación amplificaba el impacto potencial de cualquier vulnerabilidad en la aplicación.
- La ausencia de TLS permitía interceptar las comunicaciones en texto plano.


## 2. ¿Qué configuración representaba el mayor riesgo?

La configuración de mayor riesgo fue la regla permisiva en `pg_hba.conf`:

```
host  all  all  0.0.0.0/0  scram-sha-256
```

Esta regla es especialmente peligrosa porque:
- Elimina cualquier restricción de origen, exponiendo el servicio a todos los hosts de Internet
- Aplica a **todas** las bases de datos y **todos** los usuarios
- Hace que la contraseña sea el único control de acceso

Si esta regla hubiera usado `trust` en lugar de `scram-sha-256`, el riesgo sería aún mayor, pues cualquier host podría conectarse sin necesidad de contraseña.

El riesgo compuesto (red amplia + sin segregación de cuentas + sin TLS) creaba una superficie de ataque significativa en un servidor que potencialmente maneja información sensible.

---

## 3. ¿Qué cambio produjo la mayor reducción de exposición?

El cambio de mayor impacto fue la **restricción de las reglas de `pg_hba.conf`**, pasando de:

```
host  all  all  0.0.0.0/0  scram-sha-256
```

a:

```
host  lab_db  app_user  10.10.10.0/24  scram-sha-256
```

Este cambio, en conjunto con la restricción de `listen_addresses`, redujo la superficie de ataque de "cualquier host en Internet" a "solo hosts en la red interna 10.10.10.0/24, conectando a una base de datos específica, con un usuario específico".

La restricción de `listen_addresses` es complementaria: aunque `pg_hba.conf` restrinja los orígenes, si el servidor escucha en todas las interfaces, aún recibe conexiones TCP y puede ser sometido a ataques de denegación de servicio o a la explotación de vulnerabilidades del protocolo de red.

## 4. ¿Qué diferencia existe entre firewall y pg_hba.conf?

| Aspecto | Firewall | pg_hba.conf |
|---------|----------|-------------|
| **Capa** | Red (L3/L4) | Aplicación (PostgreSQL) |
| **Cuándo actúa** | Antes de que el paquete llegue a PostgreSQL | Después de establecida la conexión TCP |
| **Qué controla** | Qué paquetes TCP/IP pueden llegar al puerto 5432 | Qué conexiones pueden autenticarse en PostgreSQL |
| **Alcance** | Sistema operativo / dispositivo de red | Motor de base de datos |
| **Si falla uno** | El otro sigue operando | El otro sigue operando |

**Son complementarios, no equivalentes.** Un firewall que permite el tráfico pero con pg_hba.conf restrictivo sigue siendo más seguro que no tener firewall. Pero la mejor práctica es aplicar ambos controles como capas independientes (defensa en profundidad).

- **Solo firewall**: Si el firewall falla o es mal configurado, cualquier host podría llegar a pg_hba.conf. Si pg_hba.conf es permisivo, el acceso no estaría controlado.
- **Solo pg_hba.conf**: El servidor recibe conexiones TCP de cualquier origen, aunque pg_hba.conf las rechace. El servidor queda expuesto a ataques de red, escaneos y posibles vulnerabilidades del protocolo.
- **Ambos**: El firewall filtra antes de que la conexión llegue a PostgreSQL. pg_hba.conf filtra antes de que se inicie la autenticación. Doble control independiente.


## 5. ¿Qué diferencia existe entre autenticación y autorización?

**Autenticación** — Verifica *quién eres*:
- Proceso de verificar la identidad de un usuario
- Mecanismos: contraseña, certificado, Kerberos
- Resultado: identidad confirmada o rechazada
- Ejemplo: "El usuario `juan` con la contraseña correcta es quien dice ser"

**Autorización** — Determina *qué puedes hacer*:
- Proceso de verificar qué operaciones puede realizar un usuario ya autenticado
- Mecanismos: GRANT, REVOKE, RLS, roles
- Resultado: acceso permitido o denegado a recursos específicos
- Ejemplo: "`juan` puede SELECT en la tabla `clientes` pero no puede DELETE"

**Son independientes y ambos son necesarios:**
- Un usuario puede estar autenticado pero sin autorización para hacer nada útil
- Un usuario puede tener autorización a recursos, pero sin autenticarse, no puede acceder
- Tener una contraseña fuerte no garantiza que los privilegios estén correctamente asignados


## 6. ¿Por qué una cuenta de aplicación no debe ser SUPERUSER?

Una cuenta `SUPERUSER` en PostgreSQL puede:
1. **Ejecutar cualquier operación** — `DROP DATABASE`, `DROP TABLE`, `TRUNCATE` en cualquier tabla
2. **Saltarse el RLS** — Ignorar políticas de Row Level Security
3. **Acceder a archivos del SO** — `COPY TO '/etc/shadow'` o equivalente
4. **Crear/eliminar roles** — Escalar privilegios o crear backdoors
5. **Modificar la configuración** — Alterar parámetros del servidor
6. **Acceder a pg_shadow** — Ver hashes de contraseñas de otros usuarios

Si la aplicación se conecta como `SUPERUSER` y es comprometida (inyección SQL, vulnerabilidad en el código), el atacante hereda automáticamente todos esos privilegios. El daño potencial es máximo.

Con una cuenta `app_user` de mínimos privilegios:
- El atacante solo puede ejecutar las operaciones que la aplicación necesita
- No puede eliminar bases de datos ni modificar la configuración
- No puede escalar privilegios
- El daño está contenido al scope de la aplicación


## 7. ¿Por qué cambiar el puerto de PostgreSQL no constituye hardening suficiente?

Cambiar el puerto de `5432` a otro valor (ej. `15432`) es una medida de **oscuridad**, no de **seguridad**:

1. **Los escáneres de puertos detectan servicios por banner**, no por número de puerto. `nmap -sV` identifica PostgreSQL en cualquier puerto.
2. **Reduce ruido automatizado** (bots que escanean el puerto 5432 por defecto), pero no protege contra atacantes dirigidos.
3. **No reemplaza autenticación**: si la contraseña es débil, el servicio sigue siendo vulnerable.
4. **No reemplaza autorización**: los privilegios excesivos siguen siendo un riesgo.
5. **No cifra las comunicaciones**: el canal sigue siendo texto plano sin TLS.
6. **No restringe los orígenes**: sin pg_hba.conf restrictivo, cualquier host puede intentar conectarse al nuevo puerto.

El cambio de puerto puede ser parte de una estrategia de reducción de ruido, pero nunca como sustituto de controles reales.


## 8. ¿Por qué `listen_addresses='*'` puede ser innecesario?

La mayoría de los servidores PostgreSQL en entornos de producción:
- Reciben conexiones solo desde servidores de aplicación en la misma red privada
- No necesitan ser accesibles desde Internet directamente
- Pueden operar perfectamente con `listen_addresses = '10.10.10.20'` o `'localhost'`

`listen_addresses = '*'` es necesario **solo** cuando:
- El servidor necesita recibir conexiones en múltiples interfaces que no se pueden enumerar fácilmente
- La arquitectura requiere acceso desde redes múltiples sin poder usar un reverse proxy o pgBouncer

En el 99% de los casos, enumerar explícitamente las interfaces necesarias es más seguro y no impacta la funcionalidad real de la aplicación.


## 9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?

El sistema operativo es la **primera capa de defensa** y la **base de confianza** sobre la que opera PostgreSQL:

1. **Permisos de archivos de configuración** — Si `pg_hba.conf` es legible por otros usuarios del SO, la configuración de autenticación queda expuesta. Si es modificable, cualquier usuario podría alterar las reglas de acceso.

2. **Permisos del directorio de datos** — Los archivos de datos de PostgreSQL son archivos del sistema de archivos. Sin permisos restrictivos, podrían ser leídos, copiados o modificados directamente (fuera del motor).

3. **Usuario del servicio** — PostgreSQL debe ejecutarse como un usuario sin privilegios de root. Si el proceso es comprometido con un usuario de root, el atacante controla el sistema completo.

4. **Firewall del SO** — `iptables`, `nftables` o `ufw` actúan como filtro antes de que el tráfico llegue al proceso de PostgreSQL.

5. **Auditoría del SO** — Los logs del sistema pueden complementar los logs de PostgreSQL para detectar accesos físicos a los archivos.

**Conclusión:** Los controles de PostgreSQL (`GRANT`, `REVOKE`, `pg_hba.conf`) no protegen contra un atacante con acceso directo al sistema de archivos. La seguridad del SO es una capa independiente y necesaria.


## 10. ¿Qué controles deberían revisarse periódicamente?

| Control | Frecuencia | Razón |
|---------|-----------|-------|
| Roles y privilegios | Trimestral | Los empleados cambian, las aplicaciones evolucionan |
| Reglas de pg_hba.conf | Mensual o ante cambios | La arquitectura de red puede cambiar |
| Versión de PostgreSQL | Continua | Parches de seguridad |
| Extensiones instaladas | Trimestral | Puede acumularse funcionalidad innecesaria |
| Usuarios con SUPERUSER | Mensual | Verificar que no se agregaron cuentas inadecuadas |
| Logs de conexión | Semanal | Detectar anomalías o intentos fallidos |
| Permisos del SO en archivos conf | Semestral | Pueden alterarse por actualizaciones o procesos del SO |
| Configuración TLS | Anual | Las versiones del protocolo y ciphers evolucionan |
| Backups del baseline | Trimestral | Mantener una referencia de la configuración correcta |
| Contraseñas de cuentas de servicio | Semestral o ante incidente | Reducir el impacto de filtraciones |


## Reflexión — ¿Qué cambiaría primero?

Si recibiera la responsabilidad de asegurar un servidor PostgreSQL ya funcionando en producción, **el primer cambio sería restringir las reglas de `pg_hba.conf`**, seguido inmediatamente de `listen_addresses`.

**Razones:**

1. **Riesgo máximo**: Una regla `0.0.0.0/0` expone el servidor a todos los hosts de Internet. Es el vector más amplio posible.

2. **Exposición activa**: A diferencia de una contraseña débil (que requiere que alguien la pruebe), una configuración de red permisiva es un problema persistente y activo mientras el servidor esté encendido.

3. **Impacto contenido del cambio**: Restringir pg_hba.conf a las redes que realmente deben tener acceso no interrumpe a los usuarios legítimos, pero elimina inmediatamente la exposición innecesaria.

4. **No requiere reinicio**: `SELECT pg_reload_conf();` aplica los cambios de pg_hba.conf sin interrumpir el servicio.

5. **Base para otros cambios**: Una vez que la red está restringida, los demás controles (cuentas, TLS, timeouts) pueden implementarse de forma ordenada sin la urgencia de una exposición activa.

La contraseña fuerte, TLS y las cuentas con mínimo privilegio son igualmente importantes, pero la exposición de red es el riesgo más inmediato y con mayor superficie de ataque potencial. Reducir el blast radius primero es la prioridad.

---

## Evaluación del proceso

La seguridad de una base de datos no depende de un único control:

```
Sistema operativo (permisos de archivos, usuario del servicio)
        ↓
Red / Firewall (filtrado de paquetes)
        ↓
listen_addresses (interfaces de escucha)
        ↓
pg_hba.conf (autenticación basada en host)
        ↓
Autenticación (scram-sha-256)
        ↓
Autorización (roles, privilegios, RLS)
        ↓
TLS (cifrado del canal)
        ↓
Datos (cifrado de datos sensibles)
        ↓
Aplicación (validación de entrada, ORM seguro)
```

Cada capa protege contra fallas de las otras. El hardening es el proceso de asegurar que cada capa esté correctamente configurada y sea tan específica como sea necesario.