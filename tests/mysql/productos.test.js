const mysql = require('mysql2/promise');
const config = require('../config');

// Test data
const testProducto = {
  id: 'test-' + Date.now(),
  nombre: 'Producto de Prueba',
  descripcion: 'Este es un producto de prueba',
  precio_base: 99.99,
  categoria: 'test',
  estado: 'activo'
};

const testDimensiones = {
  id_producto: '', // Will be set in the first test
  ancho: 10.5,
  alto: 20.5,
  profundo: 15.0
};

describe('MySQL Database Tests - Productos', () => {
  let connection;

  beforeAll(async () => {
    // Create a connection to the database
    connection = await mysql.createConnection({
      ...config.mysql,
      multipleStatements: true
    });
  });

  afterAll(async () => {
    // Clean up and close the connection
    if (connection) {
      await connection.execute('DELETE FROM dimensiones WHERE id_producto LIKE ?', ['test-%']);
      await connection.execute('DELETE FROM productos WHERE id LIKE ?', ['test-%']);
      await connection.end();
    }
  });

  test('1. CREATE - Debe insertar un nuevo producto', async () => {
    const [result] = await connection.execute(
      'INSERT INTO productos (id, nombre, descripcion, precio_base, categoria, estado) VALUES (?, ?, ?, ?, ?, ?)',
      [testProducto.id, testProducto.nombre, testProducto.descripcion, 
       testProducto.precio_base, testProducto.categoria, testProducto.estado]
    );
    
    expect(result.affectedRows).toBe(1);
    
    // Set the product ID for dimensiones test
    testDimensiones.id_producto = testProducto.id;
  });

  test('2. READ - Debe recuperar el producto insertado', async () => {
    const [rows] = await connection.execute(
      'SELECT * FROM productos WHERE id = ?',
      [testProducto.id]
    );
    
    expect(rows.length).toBe(1);
    const producto = rows[0];
    expect(producto.nombre).toBe(testProducto.nombre);
    expect(parseFloat(producto.precio_base)).toBe(testProducto.precio_base);
  });

  test('3. UPDATE - Debe actualizar el producto', async () => {
    const nuevoPrecio = 129.99;
    const [result] = await connection.execute(
      'UPDATE productos SET precio_base = ? WHERE id = ?',
      [nuevoPrecio, testProducto.id]
    );
    
    expect(result.affectedRows).toBe(1);
    
    // Verify the update
    const [rows] = await connection.execute(
      'SELECT precio_base FROM productos WHERE id = ?',
      [testProducto.id]
    );
    expect(parseFloat(rows[0].precio_base)).toBe(nuevoPrecio);
  });

  test('4. CREATE - Debe insertar dimensiones para el producto', async () => {
    const [result] = await connection.execute(
      'INSERT INTO dimensiones (id_producto, ancho, alto, profundo) VALUES (?, ?, ?, ?)',
      [testDimensiones.id_producto, testDimensiones.ancho, 
       testDimensiones.alto, testDimensiones.profundo]
    );
    
    expect(result.affectedRows).toBe(1);
  });

  test('5. READ - Debe recuperar las dimensiones del producto', async () => {
    const [rows] = await connection.execute(
      'SELECT * FROM dimensiones WHERE id_producto = ?',
      [testDimensiones.id_producto]
    );
    
    expect(rows.length).toBe(1);
    const dim = rows[0];
    expect(parseFloat(dim.ancho)).toBe(testDimensiones.ancho);
    expect(parseFloat(dim.alto)).toBe(testDimensiones.alto);
    expect(parseFloat(dim.profundo)).toBe(testDimensiones.profundo);
  });

  test('6. DELETE - Debe eliminar las dimensiones y el producto', async () => {
    // Delete dimensiones first (due to foreign key constraint)
    const [dimResult] = await connection.execute(
      'DELETE FROM dimensiones WHERE id_producto = ?',
      [testDimensiones.id_producto]
    );
    
    // Delete the product
    const [prodResult] = await connection.execute(
      'DELETE FROM productos WHERE id = ?',
      [testProducto.id]
    );
    
    expect(dimResult.affectedRows).toBe(1);
    expect(prodResult.affectedRows).toBe(1);
  });
});
