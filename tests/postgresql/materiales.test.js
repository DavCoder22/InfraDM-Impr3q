const { Pool } = require('pg');
const config = require('../config');

// Test data
const testMaterial = {
  id: 'test-' + Date.now(),
  nombre: 'Material de Prueba',
  tipo: 'filamento',
  fabricante: 'Test Labs',
  disponible: true,
  stock: 100.0,
  precio_por_unidad: 29.99
};

const testCaracteristicas = {
  id_material: '', // Will be set in the first test
  color: 'negro',
  temperatura_impresion: 210,
  temperatura_plataforma: 60,
  resistencia_tensil: 50.5,
  dureza: 98.0,
  diametro_filamento: 1.75,
  densidad: 1.24,
  viscosidad: 350.0,
  tiempo_cura: 8,
  tolerancia: 0.1
};

describe('PostgreSQL Database Tests - Materiales', () => {
  let pool;
  let client;

  beforeAll(async () => {
    // Create a connection pool
    pool = new Pool(config.postgres);
    client = await pool.connect();
  });

  afterAll(async () => {
    // Clean up and release the client
    if (client) {
      await client.query('DELETE FROM caracteristicas_materiales WHERE id_material LIKE $1', ['test-%']);
      await client.query('DELETE FROM materiales WHERE id LIKE $1', ['test-%']);
      await client.release();
    }
    if (pool) {
      await pool.end();
    }
  });

  test('1. CREATE - Debe insertar un nuevo material', async () => {
    const result = await client.query(
      'INSERT INTO materiales (id, nombre, tipo, fabricante, disponible, stock, precio_por_unidad) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
      [testMaterial.id, testMaterial.nombre, testMaterial.tipo, testMaterial.fabricante, 
       testMaterial.disponible, testMaterial.stock, testMaterial.precio_por_unidad]
    );
    
    expect(result.rowCount).toBe(1);
    
    // Set the material ID for caracteristicas test
    testCaracteristicas.id_material = testMaterial.id;
  });

  test('2. READ - Debe recuperar el material insertado', async () => {
    const result = await client.query(
      'SELECT * FROM materiales WHERE id = $1',
      [testMaterial.id]
    );
    
    expect(result.rows.length).toBe(1);
    const material = result.rows[0];
    expect(material.nombre).toBe(testMaterial.nombre);
    expect(parseFloat(material.precio_por_unidad)).toBe(testMaterial.precio_por_unidad);
    expect(material.disponible).toBe(true);
  });

  test('3. UPDATE - Debe actualizar el material', async () => {
    const nuevoPrecio = 34.99;
    const result = await client.query(
      'UPDATE materiales SET precio_por_unidad = $1 WHERE id = $2',
      [nuevoPrecio, testMaterial.id]
    );
    
    expect(result.rowCount).toBe(1);
    
    // Verify the update
    const verifyResult = await client.query(
      'SELECT precio_por_unidad FROM materiales WHERE id = $1',
      [testMaterial.id]
    );
    expect(parseFloat(verifyResult.rows[0].precio_por_unidad)).toBe(nuevoPrecio);
  });

  test('4. CREATE - Debe insertar características para el material', async () => {
    const result = await client.query(
      `INSERT INTO caracteristicas_materiales 
       (id_material, color, temperatura_impresion, temperatura_plataforma, 
        resistencia_tensil, dureza, diametro_filamento, densidad, 
        viscosidad, tiempo_cura, tolerancia) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        testCaracteristicas.id_material,
        testCaracteristicas.color,
        testCaracteristicas.temperatura_impresion,
        testCaracteristicas.temperatura_plataforma,
        testCaracteristicas.resistencia_tensil,
        testCaracteristicas.dureza,
        testCaracteristicas.diametro_filamento,
        testCaracteristicas.densidad,
        testCaracteristicas.viscosidad,
        testCaracteristicas.tiempo_cura,
        testCaracteristicas.tolerancia
      ]
    );
    
    expect(result.rowCount).toBe(1);
  });

  test('5. READ - Debe recuperar las características del material', async () => {
    const result = await client.query(
      'SELECT * FROM caracteristicas_materiales WHERE id_material = $1',
      [testCaracteristicas.id_material]
    );
    
    expect(result.rows.length).toBe(1);
    const caracteristicas = result.rows[0];
    expect(caracteristicas.color).toBe(testCaracteristicas.color);
    expect(caracteristicas.temperatura_impresion).toBe(testCaracteristicas.temperatura_impresion);
    expect(parseFloat(caracteristicas.densidad)).toBe(testCaracteristicas.densidad);
  });

  test('6. DELETE - Debe eliminar las características y el material', async () => {
    // Delete características first (due to foreign key constraint)
    const delCaracteristicas = await client.query(
      'DELETE FROM caracteristicas_materiales WHERE id_material = $1',
      [testCaracteristicas.id_material]
    );
    
    // Delete the material
    const delMaterial = await client.query(
      'DELETE FROM materiales WHERE id = $1',
      [testMaterial.id]
    );
    
    expect(delCaracteristicas.rowCount).toBe(1);
    expect(delMaterial.rowCount).toBe(1);
  });
});
