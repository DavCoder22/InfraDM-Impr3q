# Pruebas de Base de Datos

Este directorio contiene pruebas CRUD para verificar la funcionalidad de las bases de datos en el proyecto InfraDM-Impr3q.

## Requisitos Previos

1. Asegúrate de que los siguientes servicios estén en ejecución:
   - MySQL (puerto 3307)
   - PostgreSQL (puerto 55432)
   - MongoDB (puerto 27018)
   - Redis (puerto 6380)

2. Instala las dependencias:
   ```bash
   npm install
   ```

## Configuración

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables de entorno (o configura los valores en `tests/config.js`):

```env
# MySQL Configuration
MYSQL_USER=test_user
MYSQL_PASSWORD=test_password
MYSQL_DATABASE=test_db

# PostgreSQL Configuration
POSTGRES_USER=test_user
POSTGRES_PASSWORD=test_password
POSTGRES_DB=test_db

# MongoDB Configuration
MONGO_ROOT_USERNAME=test_user
MONGO_ROOT_PASSWORD=test_password
MONGO_DATABASE=test_db

# Redis Configuration
REDIS_PASSWORD=test_password
```

## Ejecutando las Pruebas

Para ejecutar todas las pruebas:
```bash
npm test
```

Para ejecutar pruebas específicas:

- Pruebas de MySQL:
  ```bash
  npm run test:mysql
  ```

- Pruebas de PostgreSQL:
  ```bash
  npm run test:postgres
  ```

- Pruebas de MongoDB:
  ```bash
  npm run test:mongo
  ```

- Pruebas de Redis:
  ```bash
  npm run test:redis
  ```

## Estructura de las Pruebas

Cada conjunto de pruebas incluye operaciones CRUD completas:

1. **MySQL**: Pruebas para las tablas `productos` y `dimensiones`
2. **PostgreSQL**: Pruebas para las tablas `materiales` y `caracteristicas_materiales`
3. **MongoDB**: Pruebas para las colecciones `product_images` y `category_images`
4. **Redis**: Pruebas de operaciones básicas de caché y hashes

## Depuración

- Las pruebas están configuradas con un tiempo de espera de 15 segundos por prueba.
- Los datos de prueba se limpian automáticamente después de cada ejecución.
- Los registros de prueba tienen el prefijo 'test-' seguido de una marca de tiempo para evitar conflictos.

## Notas

- Asegúrate de que las bases de datos tengan los esquemas necesarios antes de ejecutar las pruebas.
- Las credenciales predeterminadas se pueden modificar en `tests/config.js`.
- Las pruebas están diseñadas para ser independientes y se pueden ejecutar en cualquier orden.
