**Actividad 8 — Analizar un escenario de seguridad**

Considera la siguiente situación:
Una empresa almacena los siguientes elementos:

    * nombre

    * correo electrónico

    * contraseña

    * RFC

    * información financiera

    * claves criptográficas

La base de datos utiliza usuarios y roles correctamente.
Sin embargo:

    * las contraseñas están almacenadas en texto claro

    * el RFC está almacenado en texto claro

    * las conexiones utilizan una configuración sin validación adecuada del servidor

    * las claves criptográficas aparecen en archivos SQL

    * los respaldos se almacenan sin protección adicional


#### Preguntas

* **Pregunta 1: ¿Cuáles son los principales riesgos?**
  Una fuga de datos mostraria todas las contraseñas de todos los usuarios. Exposicion del RFC y datos financieros en texto claro. Claves en SQL permiten a atacantes descifrar cualquier dato protegido. Respaldos expuestos pueden ser restaurados en cualquier servidor de un atacante.

* **Pregunta 2: ¿Qué mecanismo utilizarías para cada elemento?** Control de acceso, Para la contraseña Hashing con sal. Gestor de claves. TLS y cifrado asimétrico de los archivos.

* **Pregunta 3: ¿Cuál de los problemas consideras más crítico y por qué?**
  Las claves expuestas y las contraseñas en texto claro. Ya que si las claves y las contraseñas están expuestas, todo lo demás queda totalmente colapsadas de forma inmediata. Asi la seguridad colapsa porque el atacante posee las llaves maestras del sistema.

* **Pregunta 4: ¿Tener correctamente configurados los usuarios y permisos elimina estos riesgos?**  
  No, ya que el control de acceso es solo una capa de seguridad. Si un atacante vulnera la red, los permisos de no impedirán que lea las tablas si la información y los archivos no están cifrados.