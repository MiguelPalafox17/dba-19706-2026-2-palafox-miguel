**Actividad 10 — Crear una Política Mínima de Protección de Claves**

1. **Generación Segura:** Las claves criptográficas deben ser generadas por números pseudoaleatorios para cifrado.
2. **Prohibición de Secretos en Código Fuente:** Queda estrictamente prohibido incluir contraseñas, claves criptográficas, tokens o API keys en el código fuente, y en los scripts SQL.
3. **Almacenamiento Externalizado:** Las claves deben almacenarse en un gestor de secretos especializado.
4. **Principio de Mínimo Privilegio de Acceso:** El acceso a las claves de descifrado deben estar limitadas.
5. **Separación de Entornos:** Quedan estrictamente prohibido utilizar las mismas claves criptográficas o credenciales en los entornos de desarrollo, pruebas y producción.
6. **Rotación Periódica y Programada:** Las claves criptográficas de producción deben rotarse como mínimo una vez al año, o de forma inmediata ante cualquier sospecha de compromiso.
7. **Revocación de Claves:** Se debe contar con un procedimiento documentado para revocar y retirar de servicio inmediatamente cualquier clave comprometida.