#### Tabla Comparativa de Mecanismos de Protección

| Situación | Mecanismo apropiado | ¿Qué protege? |
| :--- | :--- | :--- |
| **Contraseña de usuario** | Password Hashing bcrypt con salt | Protege la informacion contra filtraciones o lectura directa en la base de datos, asi impidiendo que la contraseña real sea reversible. |
| **RFC almacenado en una tabla** | Cifrado simetrico | Protege la confidencialidad de la informacion confidencial en reposo dentro de la tabla contra usuarios con acceso a la base de datos. |
| **Consulta enviada desde un cliente al servidor** | Cifrado en transito via TLS | Protege la comunicación en transito contra captura de paquetes, alteracion de datos e intercepcion |
| **Respaldo de una base de datos** | Cifrado de respaldos | Protege los archivos de respaldo en reposo contra acceso no autorizado en almacenamiento secundario o nubes. |
| **Clave criptografica** | Gestor de Claves/Variables de entorno protegidas | Protege el secreto raiz impidiendo su visualizacion en codigo fuente, repositorios, logs o esquemas de base de datos. |