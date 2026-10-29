### 1. Introducción
Durante el presente laboratorio se abordo la proteccion integral de una base de datos mediante mecanismos de seguridad criptografica en tres frentes fundamentales: credenciales de acceso, datos confidenciales en reposo y canales de comunicacion en transito.

### 2. Protección de Credenciales
Se demostro que almacenar contraseñas en texto claro expone a la organizacion a filtraciones catastroficas. La solucion aplicada consiste en el hashing unidireccional con sal `bcrypt` / `crypt()`, garantizando que la contraseña no sea recuperable pero sí verificable.

### 3. Protección de Datos Sensibles
Se aplico cifrado simetrico mediante la extensión `pgcrypto`. A diferencia de las contraseñas, los datos sensibles del negocio requieren ser leídos en su forma original por personal o procesos autorizados.

### 4. TLS
Se verifico la configuracion de TLS en PostgreSQL. TLS protege la comunicación en transito contra intercepción y manipulacian.

### 5. Gestión de Claves
Se concluyo que la solidez de la criptografía no radica en el secreto del algoritmo, sino en la custodia de la clave. Incluir claves en scripts SQL expone el sistema completo a través del historial de control de versiones.

### 6. Resultados
* Creación de un esquema seguro de usuarios con `bcrypt`.
* Cifrado y descifrado de campos RFC con OpenPGP.
* Auditoría de la vista `pg_stat_ssl` confirmando conexiones cifradas.
* Definición de la política corporativa para la gestión de llaves.

### 7. Problemas Encontrados y Soluciones
* **Dificultad:** Error al verificar los servicios de TLS, ya que mi equipo no cuenta con el ambiente necesario para realizarlo.
* **Dificultad:** Error al descifrar datos con `pgp_sym_decrypt` por discrepancias en la clave.
* **Solución:** Se validó la precisión de la frase de paso y se reafirmó la necesidad de automatizar la inyección de claves mediante variables de entorno para evitar errores de tipeo manual.


-----------------------------------------------------------------------------------------------

1. **¿Por qué una contraseña no debe almacenarse como texto claro?**  
   Porque cualquier vulnerabilidad que permita la lectura no autorizada de la tabla expondria directamente la informacion de los usuarios, asi permitiendo la suplantación de identidad.

2. **¿Por qué un hash no es equivalente a un cifrado?**  
   El hash es una transformacion unidireccional diseñada para verificar integridad y autenticar sin revelar el dato. El cifrado es bidireccional para proteger datos que deben volver a su estado original.

3. **¿Por qué el cifrado de una columna no sustituye al control de acceso?**  
   El cifrado de columna protege la confidencialidad en reposo. El control de acceso determina quien tiene derecho a ejecutar actividades. Un usuario con solo permiso para consultar la columna cifrada pero sin la clave solo mirara un bloque ininteligible de bytes, demostrando que ambos controles son complementarios.

4. **¿Por qué TLS no sustituye a los mecanismos de autorización de PostgreSQL?**  
   TLS asegura el canal de comunicación, pero no determina a que tablas o filas tiene derecho a acceder el cliente autenticado una vez conectado al servidor.

5. **¿Qué ocurriría si una organización pierde una clave utilizada para cifrar información?**  
   La informacion cifrada con esa clave se volveria permanentemente inaccesible.

6. **¿Qué ocurriría si una clave criptográfica se publica accidentalmente en GitLab?**  
   Cualquiera con acceso al repositorio podrá extraer la clave. Y si obtienen acceso a la base de datos o a un respaldo, podrán descifrar toda la información protegida.

7. **¿Por qué un repositorio privado no debe considerarse un almacén de secretos?**  
   Porque un repositorio privado no garantiza confidencialidad absolutam, ya que el personal con acceso cambia las computadoras de los desarrolladores que pueden ser vulneradas y el historial de Git conserva el secreto indefinidamente aunque el archivo sea eliminado.

8. **¿Qué diferencia existe entre proteger información almacenada y proteger información durante su transmisión?**  
   Proteger información almacenada, que prevee acceso directo a los archivos en disco, bases de datos o respaldos. Proteger la transmisión el cual evita la intercepción de los datos mientras viajan por la red física o lógica entre el cliente y el servidor.

9. **¿Por qué la gestión de claves es tan importante como el algoritmo criptográfico?**  
   Porque los algoritmos estándar son públicos y han sido probados matemáticamente. La seguridad real del sistema recae por completo en la confidencialidad y control de la clave.

10. **¿Qué mecanismo adicional implementarías en una organización para proteger los respaldos de las bases de datos?**  
    Implementar un cifrado asimetrico en el archivo de respaldo inmediatamente despues de su generacion y enviar el archivo cifrado a un almacenamiento secundario.