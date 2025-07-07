const { createClient } = require('redis');
const config = require('../config');

// Test data
const testKey = 'test:key:' + Date.now();
const testValue = {
  id: 'test-' + Date.now(),
  name: 'Test Cache Item',
  value: 42,
  timestamp: new Date().toISOString()
};

describe('Redis Cache Tests', () => {
  let client;

  beforeAll(async () => {
    // Create a Redis client
    client = createClient({
      socket: {
        host: config.redis.host,
        port: config.redis.port
      },
      password: config.redis.password,
      database: config.redis.db
    });

    // Handle connection errors
    client.on('error', (err) => console.error('Redis Client Error', err));
    
    // Connect to Redis
    await client.connect();
  });

  afterAll(async () => {
    // Clean up and close the connection
    if (client) {
      // Delete test keys
      await client.del(testKey);
      await client.quit();
    }
  });

  test('1. SET - Debe establecer un valor en la caché', async () => {
    const result = await client.set(testKey, JSON.stringify(testValue));
    expect(result).toBe('OK');
  });

  test('2. GET - Debe recuperar el valor de la caché', async () => {
    const value = await client.get(testKey);
    expect(value).toBeDefined();
    
    const parsedValue = JSON.parse(value);
    expect(parsedValue.id).toBe(testValue.id);
    expect(parsedValue.name).toBe(testValue.name);
  });

  test('3. EXISTS - Debe verificar que la clave existe', async () => {
    const exists = await client.exists(testKey);
    expect(exists).toBe(1);
  });

  test('4. EXPIRE - Debe establecer un tiempo de expiración', async () => {
    const result = await client.expire(testKey, 60); // 60 seconds
    expect(result).toBe(true);
    
    // Verify TTL is set
    const ttl = await client.ttl(testKey);
    expect(ttl).toBeGreaterThan(0);
    expect(ttl).toBeLessThanOrEqual(60);
  });

  test('5. DEL - Debe eliminar la clave de la caché', async () => {
    const result = await client.del(testKey);
    expect(result).toBe(1);
    
    // Verify the key is deleted
    const exists = await client.exists(testKey);
    expect(exists).toBe(0);
  });

  test('6. HASH - Debe manejar operaciones con hashes', async () => {
    const hashKey = 'test:hash:' + Date.now();
    const field1 = 'field1';
    const value1 = 'value1';
    const field2 = 'field2';
    const value2 = JSON.stringify({ test: 'data' });
    
    // HSET
    const hsetResult = await client.hSet(hashKey, field1, value1);
    expect(hsetResult).toBe(1);
    
    // HGET
    const hgetResult = await client.hGet(hashKey, field1);
    expect(hgetResult).toBe(value1);
    
    // HSET with multiple fields
    const hmsetResult = await client.hSet(hashKey, [field2, value2]);
    expect(hmsetResult).toBe(1);
    
    // HGETALL
    const hgetallResult = await client.hGetAll(hashKey);
    expect(hgetallResult[field1]).toBe(value1);
    expect(hgetallResult[field2]).toBe(value2);
    
    // Clean up
    await client.del(hashKey);
  });
});
