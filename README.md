# InfraDM-Impr3q

Infrastructure repository for the Distributed Programming project with a microservices architecture and mixed database setup (PostgreSQL + MongoDB + MySQL + Redis).

## 🏗️ Arquitectura del Sistema

### Componentes Principales

1. **API Gateway** - Punto de entrada único para todas las peticiones
2. **Microservicios** - Hasta 30 servicios independientes
3. **Load Balancers** - ALB para API Gateway, NLB para microservicios
4. **Bases de Datos** - PostgreSQL, MongoDB, MySQL, Redis
5. **Monitoreo** - CloudWatch, Site24x7, Grafana

### Diagrama de Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cliente Web   │    │   Cliente API   │    │   Site24x7      │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │   Application Load        │
                    │   Balancer (ALB)          │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   API Gateway             │
                    │   (Auto Scaling Group)    │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   Network Load            │
                    │   Balancer (NLB)          │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
│ Microservicio 1   │  │ Microservicio 2   │  │ Microservicio N   │
│ (Products)        │  │ (Materials)       │  │ (Users)           │
│ Puerto: 3001      │  │ Puerto: 3002      │  │ Puerto: 3005      │
└─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │   Bases de Datos          │
                    │   PostgreSQL + MongoDB    │
                    │   MySQL + Redis           │
                    └───────────────────────────┘
```

## 🚀 Características Implementadas

### ✅ **Infraestructura como Código (IaC)**
- **Terraform** para gestión completa de infraestructura
- **Auto Scaling Groups** para escalabilidad automática
- **Load Balancers** para alta disponibilidad
- **VPC con múltiples AZ** para redundancia

### ✅ **Microservicios Escalables**
- **API Gateway** con proxy inteligente
- **5 microservicios base** (expandible a 30)
- **Comunicación HTTP** entre servicios
- **Health checks** automáticos

### ✅ **Bases de Datos Mixtas**
- **PostgreSQL**: Datos estructurados
- **MongoDB**: Documentos y metadatos
- **MySQL**: Datos transaccionales
- **Redis**: Cache y sesiones

### ✅ **Observabilidad Completa**
- **CloudWatch Dashboard** automático
- **Logs centralizados** con retención configurable
- **Métricas en tiempo real**
- **Integración Site24x7** y **Grafana**

### ✅ **Documentación API con Swagger**
- **Swagger UI** integrado en API Gateway
- **Documentación automática** de endpoints
- **Testing interactivo** de APIs
- **Esquemas de base de datos** documentados

## 📋 Prerrequisitos

### Herramientas Requeridas
- **Docker** y **Docker Compose**
- **Node.js 18+**
- **AWS CLI** configurado
- **Terraform 1.0+**
- **Git**

### Cuenta AWS
- **Cuenta AWS** con permisos apropiados
- **Key Pair** creado en AWS Console
- **Créditos suficientes** para recursos (~$103/mes)

## 🛠️ Configuración Local

### 1. Clonar Repositorio
```bash
git clone https://github.com/your-username/InfraDM-Impr3q.git
cd InfraDM-Impr3q
```

### 2. Configurar Variables de Entorno
```bash
cp .env.example .env
# Editar .env con tus configuraciones
```

### 3. Iniciar Entorno de Desarrollo
```bash
docker-compose up -d
```

### 4. Acceder a la Aplicación
- **API Gateway**: http://localhost:3000
- **Swagger UI**: http://localhost:3000/api-docs
- **Health Check**: http://localhost:3000/health

## ☁️ Despliegue en AWS

### Configuración Rápida

#### 1. Preparar AWS
```bash
# Configurar AWS CLI
aws configure

# Crear key pair en AWS Console
# Descargar archivo .pem
chmod 400 your-key.pem
```

#### 2. Configurar Terraform
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars con tus valores:
# - key_name: Tu key pair
# - db_password: Contraseña PostgreSQL
# - mysql_password: Contraseña MySQL
# - mongodb_password: Contraseña MongoDB
# - redis_password: Contraseña Redis
# - jwt_secret: Secret JWT
```

#### 3. Despliegue Automático
```bash
# Ejecutar script de despliegue con pruebas
./test_deployment.sh
```

#### 4. Despliegue Manual
```bash
terraform init
terraform plan
terraform apply
```

### Verificación del Despliegue

#### Verificar API Gateway
```bash
# Obtener URL del API Gateway
API_URL=$(terraform output -raw api_gateway_url)

# Probar health check
curl $API_URL/health

# Probar Swagger UI
curl $API_URL/api-docs

# Probar endpoint principal
curl $API_URL/api
```

#### Verificar Microservicios
```bash
# Obtener DNS del NLB
NLB_DNS=$(terraform output -raw microservices_nlb_dns_name)

# Probar cada microservicio
for i in {1..5}; do
  PORT=$((3000 + i))
  echo "Testing microservice $i on port $PORT"
  curl -s "http://$NLB_DNS:$PORT/health" || echo "Service $i not ready yet"
done
```

## 📊 Microservicios Implementados

### 1. **Products Service** (Puerto 3001)
- Gestión de productos
- CRUD completo
- Búsqueda y filtros
- Integración con PostgreSQL

### 2. **Materials Service** (Puerto 3002)
- Gestión de materiales
- Categorización
- Propiedades técnicas
- Integración con MongoDB

### 3. **Categories Service** (Puerto 3003)
- Gestión de categorías
- Jerarquía de categorías
- Relaciones padre-hijo
- Integración con PostgreSQL

### 4. **Quotations Service** (Puerto 3004)
- Gestión de cotizaciones
- Cálculo de precios
- Historial de cotizaciones
- Integración con MySQL

### 5. **Users Service** (Puerto 3005)
- Gestión de usuarios
- Autenticación y autorización
- Perfiles de usuario
- Integración con Redis

## 🗄️ Esquemas de Base de Datos

### PostgreSQL Tables

#### **products**
```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(50) UNIQUE NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT true
);
```

#### **materials**
```sql
CREATE TABLE materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **categories**
```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    categoria_padre_id UUID REFERENCES categories(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **product_category**
```sql
CREATE TABLE product_category (
    producto_id UUID REFERENCES products(id),
    categoria_id UUID REFERENCES categories(id),
    PRIMARY KEY (producto_id, categoria_id)
);
```

### MongoDB Collections

#### **productos_detalles**
```json
{
  "_id": "ObjectId('...')",
  "producto_id": "UUID from PostgreSQL",
  "nombre": "Product Name",
  "descripcion": "Detailed description",
  "material": {
    "id": "UUID from PostgreSQL",
    "nombre": "Material Name"
  },
  "dimensiones": {
    "largo": 10.5,
    "ancho": 5.2,
    "alto": 2.0,
    "unidad": "cm"
  },
  "imagenes": [
    {
      "url": "https://example.com/image1.jpg",
      "tipo": "principal",
      "orden": 1
    }
  ],
  "especificaciones_tecnicas": {
    "tipo_material": "PLA",
    "temperatura_impresion": 200,
    "velocidad_recomendada": 60
  }
}
```

### MySQL Tables

#### **quotations**
```sql
CREATE TABLE quotations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100),
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### **quotation_items**
```sql
CREATE TABLE quotation_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quotation_id INT REFERENCES quotations(id),
    product_id UUID,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL
);
```

## 📚 Documentación API con Swagger

### Endpoints Documentados

#### **API Gateway** (`/api-docs`)
- **Health Check**: `GET /health`
- **API Info**: `GET /api`
- **Swagger UI**: `GET /api-docs`

#### **Products Service** (`/api/products`)
```yaml
GET /api/products:
  summary: Obtener todos los productos
  parameters:
    - name: page
      in: query
      type: integer
      default: 1
    - name: limit
      in: query
      type: integer
      default: 10
  responses:
    200:
      description: Lista de productos
      schema:
        type: array
        items:
          $ref: '#/definitions/Product'

POST /api/products:
  summary: Crear nuevo producto
  parameters:
    - name: product
      in: body
      required: true
      schema:
        $ref: '#/definitions/ProductInput'
  responses:
    201:
      description: Producto creado exitosamente
```

#### **Materials Service** (`/api/materials`)
```yaml
GET /api/materials:
  summary: Obtener todos los materiales
  responses:
    200:
      description: Lista de materiales
      schema:
        type: array
        items:
          $ref: '#/definitions/Material'

POST /api/materials:
  summary: Crear nuevo material
  parameters:
    - name: material
      in: body
      required: true
      schema:
        $ref: '#/definitions/MaterialInput'
```

### Esquemas Swagger

#### **Product**
```yaml
Product:
  type: object
  properties:
    id:
      type: string
      format: uuid
    codigo:
      type: string
      maxLength: 50
    precio:
      type: number
      format: decimal
    stock:
      type: integer
    activo:
      type: boolean
    fecha_creacion:
      type: string
      format: date-time
```

#### **Material**
```yaml
Material:
  type: object
  properties:
    id:
      type: string
      format: uuid
    nombre:
      type: string
      maxLength: 100
    descripcion:
      type: string
    codigo:
      type: string
      maxLength: 50
    especificaciones_tecnicas:
      type: object
      properties:
        tipo_material:
          type: string
        temperatura_impresion:
          type: integer
        velocidad_recomendada:
          type: integer
```

## 📈 Monitoreo y Observabilidad

### CloudWatch Dashboard
- **URL**: https://console.aws.amazon.com/cloudwatch/home
- **Dashboard**: `infradm-dashboard`
- **Métricas**: Request Count, Response Time, Error Rates

### Logs Centralizados
- **API Gateway**: `/aws/ec2/infradm-api-gateway`
- **Microservicios**: `/aws/ec2/infradm-microservices`
- **Retención**: 7 días (configurable)

### Site24x7 Integration
```bash
# Endpoints automáticos para monitoreo
API_GATEWAY_URL=$(terraform output -raw api_gateway_url)
NLB_DNS=$(terraform output -raw microservices_nlb_dns_name)

# Health endpoints
echo "API Gateway Health: $API_GATEWAY_URL/health"
echo "Microservices Health: http://$NLB_DNS:3001/health"
```

### Grafana Integration
- **CloudWatch Data Source** configurado
- **Dashboards** automáticos
- **Alertas** configurables

## 💰 Estimación de Costos (us-east-1)

### Recursos Principales
- **API Gateway (t3.small)**: ~$16/mes
- **Microservicios (5x t3.micro)**: ~$40/mes
- **Load Balancers**: ~$32/mes
- **Data Transfer**: ~$10/mes
- **CloudWatch**: ~$5/mes

**Total Estimado**: ~$103/mes

### Optimización para Plan Educativo
- Instancias económicas (t3.micro, t3.small)
- Auto scaling limitado (1-5 instancias)
- Logs con retención corta (7 días)
- Sin características premium

## 🔧 Mantenimiento

### Acceso a Instancias
```bash
# API Gateway
ssh -i key.pem ubuntu@$(terraform output -raw api_gateway_public_ip)

# Microservicios
ssh -i key.pem ubuntu@$(terraform output -raw microservices_public_ip)
```

### Ver Logs
```bash
# Logs de aplicación
docker-compose logs -f app

# Logs de base de datos
docker-compose logs -f postgres
docker-compose logs -f mysql
docker-compose logs -f mongodb

# Logs de CloudWatch
aws logs tail /aws/ec2/infradm-api-gateway --follow
```

### Actualizar Aplicación
```bash
# 1. Hacer cambios y commit
git add .
git commit -m "Update application"
git push

# 2. Ejecutar despliegue
./deploy.sh
```

## 🛡️ Seguridad

### Security Groups Configurados
- **ALB**: HTTP (80), HTTPS (443)
- **NLB**: HTTP (80), Microservices (3000-3010)
- **API Gateway**: SSH (22), HTTP (80), App (3000)
- **Microservicios**: SSH (22), HTTP (80), App (3000-3010)
- **Databases**: PostgreSQL (5432), MySQL (3306), MongoDB (27017), Redis (6379)

### Recomendaciones de Seguridad
1. **Cambiar contraseñas por defecto** inmediatamente
2. **Usar AWS Secrets Manager** para producción
3. **Habilitar CloudTrail** para auditoría
4. **Configurar WAF** para protección adicional
5. **Implementar HTTPS** con certificados SSL

## 🚨 Troubleshooting

### Problemas Comunes

#### 1. Instancias no se inician
```bash
# Verificar logs de user data
aws ec2 get-console-output --instance-id <instance-id>

# Verificar security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### 2. Load Balancer no responde
```bash
# Verificar target groups
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Verificar listeners
aws elbv2 describe-listeners --load-balancer-arn <lb-arn>
```

#### 3. Microservicios no accesibles
```bash
# Verificar que las instancias estén en el target group
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Verificar connectivity desde instancia
ssh -i key.pem ubuntu@<instance-ip>
curl localhost:3001/health
```

#### 4. Swagger no carga
```bash
# Verificar que el API Gateway esté funcionando
curl $API_URL/health

# Verificar logs del API Gateway
ssh -i key.pem ubuntu@<api-gateway-ip>
tail -f /var/log/api-gateway.log
```

## 🧹 Limpieza

### Destruir Infraestructura
```bash
cd infra
terraform destroy
```

### Limpiar Archivos Locales
```bash
rm -rf .terraform
rm -f terraform.tfstate*
rm -f tfplan
rm -f deployment_outputs.json
rm -f test_report.md
```

## 📞 Soporte

Para problemas o preguntas:
1. Revisar logs de CloudWatch
2. Verificar configuración de Terraform
3. Consultar documentación de AWS
4. Revisar métricas de CloudWatch Dashboard
5. Verificar Swagger UI para testing de APIs

## 🔄 Próximos Pasos

1. **Configurar bases de datos** en subnets privadas
2. **Implementar HTTPS** con certificados SSL
3. **Configurar CI/CD** para despliegues automáticos
4. **Implementar backup** y disaster recovery
5. **Configurar alertas** en CloudWatch
6. **Optimizar costos** según uso real
7. **Expandir a 30 microservicios** según necesidades
8. **Implementar autenticación JWT** completa

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 👥 Code Owner

- @JuanGuevara90 es el code owner y debe aprobar todos los cambios en la rama `main`.

---

**InfraDM-Impr3q** - Sistema de cotización de impresión 3D con arquitectura de microservicios
