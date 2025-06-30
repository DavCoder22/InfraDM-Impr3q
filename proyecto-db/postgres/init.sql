CREATE DATABASE materiales_db;
\c materiales_db;

CREATE TABLE materiales (
    id VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    fabricante VARCHAR(100),
    disponible BOOLEAN NOT NULL,
    stock DECIMAL(10,2) NOT NULL,
    precio_por_unidad DECIMAL(10,2) NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE caracteristicas_materiales (
    id_material VARCHAR(50) PRIMARY KEY,
    color VARCHAR(50),
    temperatura_impresion INT,
    temperatura_plataforma INT,
    resistencia_tensil DECIMAL(10,2),
    dureza DECIMAL(10,2),
    diametro_filamento DECIMAL(10,2),
    densidad DECIMAL(10,2),
    viscosidad DECIMAL(10,2),
    tiempo_cura INT,
    tolerancia DECIMAL(10,2),
    FOREIGN KEY (id_material) REFERENCES materiales(id)
);
