# InfraDM-Impr3q API Documentation

## 📚 Documentación de la API con Swagger

### Acceso a la Documentación

Una vez desplegado el sistema, puedes acceder a la documentación interactiva de la API en:

- **Swagger UI**: `http://your-api-gateway-url/api-docs`
- **Swagger JSON**: `http://your-api-gateway-url/swagger.json`

### Endpoints Principales

#### 🔧 Sistema

##### Health Check
```http
GET /health
```
Verifica el estado del API Gateway y retorna información del servicio.

**Respuesta:**
```json
{
  "status": "OK",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "service": "api-gateway",
  "version": "1.0.0",
  "environment": "production"
}
```

##### Información del API Gateway
```http
GET /api
```
Obtiene información general del API Gateway y servicios disponibles.

**Respuesta:**
```json
{
  "message": "InfraDM-Impr3q API Gateway",
  "version": "1.0.0",
  "services": [
    "products",
    "materials", 
    "categories",
    "quotations",
    "users"
  ],
  "documentation": "/api-docs",
  "swagger": "/swagger.json"
}
```

#### 🛍️ Productos

##### Obtener Productos
```http
GET /api/products
```

**Parámetros de consulta:**
- `page` (integer, opcional): Número de página (default: 1)
- `limit` (integer, opcional): Elementos por página (default: 10)
- `search` (string, opcional): Término de búsqueda
- `category` (string, opcional): Filtrar por categoría

**Respuesta:**
```json
{
  "data": [
    {
      "id": "uuid-del-producto",
      "codigo": "PROD-001",
      "precio": 25.99,
      "stock": 100,
      "activo": true,
      "fecha_creacion": "2024-01-15T10:30:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 50,
    "pages": 5
  }
}
```

##### Crear Producto
```http
POST /api/products
```

**Body:**
```json
{
  "codigo": "PROD-002",
  "precio": 35.50,
  "stock": 50,
  "descripcion": "Descripción del producto"
}
```

##### Obtener Producto por ID
```http
GET /api/products/{id}
```

##### Actualizar Producto
```http
PUT /api/products/{id}
```

##### Eliminar Producto
```http
DELETE /api/products/{id}
```

#### 🧱 Materiales

##### Obtener Materiales
```http
GET /api/materials
```

**Respuesta:**
```json
{
  "data": [
    {
      "id": "uuid-del-material",
      "nombre": "PLA Premium",
      "descripcion": "Material PLA de alta calidad",
      "codigo": "MAT-001",
      "especificaciones_tecnicas": {
        "tipo_material": "PLA",
        "temperatura_impresion": 200,
        "velocidad_recomendada": 60
      }
    }
  ]
}
```

##### Crear Material
```http
POST /api/materials
```

**Body:**
```json
{
  "nombre": "ABS Industrial",
  "descripcion": "Material ABS para uso industrial",
  "codigo": "MAT-002",
  "especificaciones_tecnicas": {
    "tipo_material": "ABS",
    "temperatura_impresion": 240,
    "velocidad_recomendada": 50
  }
}
```

#### 📂 Categorías

##### Obtener Categorías
```http
GET /api/categories
```

**Respuesta:**
```json
{
  "data": [
    {
      "id": "uuid-de-la-categoria",
      "nombre": "Electrónicos",
      "descripcion": "Productos electrónicos",
      "categoria_padre_id": null,
      "subcategorias": [
        {
          "id": "uuid-subcategoria",
          "nombre": "Arduino",
          "descripcion": "Placas Arduino"
        }
      ]
    }
  ]
}
```

##### Crear Categoría
```http
POST /api/categories
```

**Body:**
```json
{
  "nombre": "Mecánicos",
  "descripcion": "Componentes mecánicos",
  "categoria_padre_id": "uuid-categoria-padre"
}
```

#### 💰 Cotizaciones

##### Obtener Cotizaciones
```http
GET /api/quotations
```

**Respuesta:**
```json
{
  "data": [
    {
      "id": 1,
      "customer_name": "Juan Pérez",
      "customer_email": "juan@example.com",
      "total_amount": 150.75,
      "status": "pending",
      "created_at": "2024-01-15T10:30:00.000Z",
      "items": [
        {
          "product_id": "uuid-producto",
          "quantity": 2,
          "unit_price": 25.99,
          "total_price": 51.98
        }
      ]
    }
  ]
}
```

##### Crear Cotización
```http
POST /api/quotations
```

**Body:**
```json
{
  "customer_name": "María García",
  "customer_email": "maria@example.com",
  "items": [
    {
      "product_id": "uuid-producto",
      "quantity": 3,
      "unit_price": 30.00
    }
  ]
}
```

#### 👥 Usuarios

##### Obtener Usuarios
```http
GET /api/users
```

**Respuesta:**
```json
{
  "data": [
    {
      "id": "uuid-del-usuario",
      "username": "admin",
      "email": "admin@infradm.com",
      "role": "admin",
      "created_at": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

##### Crear Usuario
```http
POST /api/users
```

**Body:**
```json
{
  "username": "nuevo_usuario",
  "email": "usuario@example.com",
  "password": "password123",
  "role": "user"
}
```

### Esquemas de Datos

#### Product
```yaml
Product:
  type: object
  properties:
    id:
      type: string
      format: uuid
      description: ID único del producto
    codigo:
      type: string
      maxLength: 50
      description: Código del producto
    precio:
      type: number
      format: decimal
      description: Precio del producto
    stock:
      type: integer
      description: Cantidad en stock
    activo:
      type: boolean
      description: Estado activo del producto
    fecha_creacion:
      type: string
      format: date-time
      description: Fecha de creación
```

#### Material
```yaml
Material:
  type: object
  properties:
    id:
      type: string
      format: uuid
      description: ID único del material
    nombre:
      type: string
      maxLength: 100
      description: Nombre del material
    descripcion:
      type: string
      description: Descripción del material
    codigo:
      type: string
      maxLength: 50
      description: Código del material
    especificaciones_tecnicas:
      type: object
      properties:
        tipo_material:
          type: string
          description: Tipo de material (PLA, ABS, etc.)
        temperatura_impresion:
          type: integer
          description: Temperatura de impresión recomendada
        velocidad_recomendada:
          type: integer
          description: Velocidad de impresión recomendada
```

#### Category
```yaml
Category:
  type: object
  properties:
    id:
      type: string
      format: uuid
      description: ID único de la categoría
    nombre:
      type: string
      maxLength: 100
      description: Nombre de la categoría
    descripcion:
      type: string
      description: Descripción de la categoría
    categoria_padre_id:
      type: string
      format: uuid
      description: ID de la categoría padre (opcional)
```

#### Quotation
```yaml
Quotation:
  type: object
  properties:
    id:
      type: integer
      description: ID único de la cotización
    customer_name:
      type: string
      maxLength: 100
      description: Nombre del cliente
    customer_email:
      type: string
      format: email
      description: Email del cliente
    total_amount:
      type: number
      format: decimal
      description: Monto total de la cotización
    status:
      type: string
      enum: [pending, approved, rejected]
      description: Estado de la cotización
```

#### User
```yaml
User:
  type: object
  properties:
    id:
      type: string
      format: uuid
      description: ID único del usuario
    username:
      type: string
      maxLength: 50
      description: Nombre de usuario
    email:
      type: string
      format: email
      description: Email del usuario
    role:
      type: string
      enum: [admin, user, operator]
      description: Rol del usuario
```

### Códigos de Estado HTTP

- **200 OK**: Petición exitosa
- **201 Created**: Recurso creado exitosamente
- **400 Bad Request**: Datos de entrada inválidos
- **401 Unauthorized**: No autenticado
- **403 Forbidden**: No autorizado
- **404 Not Found**: Recurso no encontrado
- **422 Unprocessable Entity**: Datos de entrada válidos pero no procesables
- **500 Internal Server Error**: Error interno del servidor
- **503 Service Unavailable**: Servicio temporalmente no disponible

### Autenticación

Actualmente la API no requiere autenticación para endpoints básicos. Para endpoints protegidos se implementará JWT en futuras versiones.

### Rate Limiting

- **Límite**: 100 requests por minuto por IP
- **Headers de respuesta**:
  - `X-RateLimit-Limit`: Límite de requests
  - `X-RateLimit-Remaining`: Requests restantes
  - `X-RateLimit-Reset`: Tiempo de reset

### Ejemplos de Uso

#### cURL

```bash
# Health check
curl -X GET "http://your-api-gateway-url/health"

# Obtener productos
curl -X GET "http://your-api-gateway-url/api/products?page=1&limit=10"

# Crear producto
curl -X POST "http://your-api-gateway-url/api/products" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo": "PROD-003",
    "precio": 45.99,
    "stock": 25
  }'

# Obtener materiales
curl -X GET "http://your-api-gateway-url/api/materials"
```

#### JavaScript (Fetch)

```javascript
// Health check
const healthCheck = async () => {
  const response = await fetch('http://your-api-gateway-url/health');
  const data = await response.json();
  console.log(data);
};

// Obtener productos
const getProducts = async (page = 1, limit = 10) => {
  const response = await fetch(
    `http://your-api-gateway-url/api/products?page=${page}&limit=${limit}`
  );
  const data = await response.json();
  return data;
};

// Crear producto
const createProduct = async (productData) => {
  const response = await fetch('http://your-api-gateway-url/api/products', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(productData),
  });
  const data = await response.json();
  return data;
};
```

#### Python (requests)

```python
import requests

# Health check
response = requests.get('http://your-api-gateway-url/health')
print(response.json())

# Obtener productos
response = requests.get('http://your-api-gateway-url/api/products', 
                       params={'page': 1, 'limit': 10})
products = response.json()
print(products)

# Crear producto
product_data = {
    'codigo': 'PROD-004',
    'precio': 55.99,
    'stock': 30
}
response = requests.post('http://your-api-gateway-url/api/products', 
                        json=product_data)
new_product = response.json()
print(new_product)
```

### Testing con Swagger UI

1. Accede a `http://your-api-gateway-url/api-docs`
2. Explora los endpoints disponibles
3. Haz clic en "Try it out" para cualquier endpoint
4. Completa los parámetros requeridos
5. Ejecuta la petición
6. Revisa la respuesta

### Notas de Desarrollo

- Todos los endpoints retornan JSON
- Las fechas están en formato ISO 8601
- Los UUIDs siguen el estándar RFC 4122
- Los errores incluyen mensajes descriptivos
- Los endpoints de listado soportan paginación
- Los endpoints de creación retornan el objeto creado

### Próximas Características

- [ ] Autenticación JWT
- [ ] Filtros avanzados
- [ ] Búsqueda full-text
- [ ] Exportación de datos
- [ ] Webhooks
- [ ] Versionado de API
- [ ] Cache con Redis
- [ ] Métricas de uso 