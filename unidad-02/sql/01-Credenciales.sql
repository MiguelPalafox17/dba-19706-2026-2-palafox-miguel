-- Creacion de la tabla insegura
CREATE TABLE usuarios_insegura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL
);
-- Insertamos datos
INSERT INTO usuarios_insegura (usuario, password)
VALUES ('juan', 'Password123');

-- Realizamos la consulta
SELECT * FROM usuarios_insegura;

-- Usamos pgcrypto para hashing seguro
SELECT crypt('Password123', gen_salt('bf'));
SELECT crypt('Password123', gen_salt('bf'));

-- Creacion de la tabla segura
CREATE TABLE usuarios_segura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);

-- Insertamos un dato a esa tabla
INSERT INTO usuarios_segura (usuario, password_hash) 
VALUES ('juan', crypt('Password123', gen_salt('bf')));

-- La consultamos
SELECT * FROM usuarios_segura;

-- Verificamos la autenticacion con el password correcto
SELECT usuario, password_hash = crypt('Password123', password_hash)
AS contraseña_correcta FROM usuarios_segura WHERE usuario = 'juan';

-- Verificamos la autenticacion con el password incorrecto
SELECT usuario, password_hash = crypt('OtraPassword', password_hash)
AS contraseña_correcta FROM usuarios_segura WHERE usuario = 'juan';