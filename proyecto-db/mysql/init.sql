CREATE DATABASE IF NOT EXISTS productos_db;
USE productos_db;

CREATE TABLE productos (
    id VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_base DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE dimensiones (
    id_producto VARCHAR(50),
    ancho DECIMAL(10,2) NOT NULL,
    alto DECIMAL(10,2) NOT NULL,
    profundo DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_producto),
    FOREIGN KEY (id_producto) REFERENCES productos(id)
);
