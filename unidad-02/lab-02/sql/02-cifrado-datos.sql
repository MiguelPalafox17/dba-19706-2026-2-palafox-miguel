-- Creacion de la tabla de clientes
CREATE TABLE clientes_protegidos ( 
	id BIGSERIAL PRIMARY KEY,
	nombre VARCHAR(120) NOT NULL,
	rfc_cifrado BYTEA NOT NULL
);

-- Insertamos un dato con cifrado
INSERT INTO clientes_protegidos ( nombre,  rfc_cifrado) 
VALUES ( 'Ana López',  pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA'));

-- Consultamos la tabla
SELECT * FROM clientes_protegidos;

-- Desciframos el dato
SELECT  id, nombre, pgp_sym_decrypt( rfc_cifrado, 'CLAVE-DE-PRUEBA'  ) 
AS rfc FROM clientes_protegidos;