# InfraDM-Impr3q

Infrastructure repository for the Distributed Programming project with a mixed database architecture (PostgreSQL + MongoDB).

## Branch Structure

- `main`: Production branch. Contains only documentation and configuration files.
- `develop`: Development branch. Contains the active source code.

## Code Owner

- @JuanGuevara90 is the code owner and must approve all changes to the `main` branch.

## Architecture Overview

This project uses a mixed database architecture:

- **PostgreSQL**: Stores structured data (products, materials, categories, product_category relationships)
- **MongoDB**: Stores product details, specifications, and media

## Prerequisites

- Docker and Docker Compose
- Node.js 18+
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform 1.0+

## Local Development

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/InfraDM-Impr3q.git
   cd InfraDM-Impr3q
   ```

2. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

3. Update the `.env` file with your configuration.

4. Start the development environment:

   ```bash
   docker-compose up -d
   ```

5. Access the application at `http://localhost:3000`

## Deployment to AWS EC2

### 1. Prepare AWS Environment

- Create an AWS IAM user with appropriate permissions
- Configure AWS CLI:

  ```bash
  aws configure
  ```
- Create an EC2 key pair and download the `.pem` file

### 2. Configure Terraform

1. Navigate to the infra directory:

   ```bash
   cd infra
   ```

2. Copy the example variables file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Update `terraform.tfvars` with your configuration:
   - `key_name`: Your EC2 key pair name
   - `db_password`: Secure PostgreSQL password
   - `mongodb_password`: Secure MongoDB password

### 3. Deploy Infrastructure

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Review the execution plan:

   ```bash
   terraform plan
   ```

3. Apply the configuration:

   ```bash
   terraform apply
   ```

4. After completion, Terraform will output the application URL and database connection details.

### 4. Deploy Application

1. Set up the deployment script:

   ```bash
   chmod +x deploy.sh
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   export AWS_REGION=$(aws configure get region)
   export PROJECT_NAME=infradm
   export SSH_KEY_PATH=path/to/your-key.pem
   ```

2. Run the deployment script:

   ```bash
   ./deploy.sh
   ```

3. The script will build and push the Docker image, then deploy it to the EC2 instance.

## Database Schema

### PostgreSQL Tables

1. **products**
   - id (UUID, PK)
   - codigo (VARCHAR, UNIQUE)
   - precio (DECIMAL)
   - stock (INTEGER)
   - fecha_creacion (TIMESTAMP)
   - fecha_actualizacion (TIMESTAMP)
   - activo (BOOLEAN)

2. **materials**
   - id (UUID, PK)
   - nombre (VARCHAR)
   - descripcion (TEXT)
   - codigo (VARCHAR, UNIQUE)
   - fecha_creacion (TIMESTAMP)

3. **categories**
   - id (UUID, PK)
   - nombre (VARCHAR)
   - descripcion (TEXT)
   - categoria_padre_id (UUID, FK, NULLABLE)
   - fecha_creacion (TIMESTAMP)

4. **product_category** (junction table)
   - producto_id (UUID, FK)
   - categoria_id (UUID, FK)
   - PRIMARY KEY (producto_id, categoria_id)

### MongoDB Collections

#### Productos Detalles
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
  ]
}
```

## Maintenance

### Accessing the EC2 Instance

```bash
ssh -i path/to/your-key.pem ubuntu@public-ip-address
```

### Viewing Logs

```bash
# Application logs
docker-compose logs -f app

# Database logs (PostgreSQL)
docker-compose logs -f postgres

# MongoDB logs
docker-compose logs -f mongodb
```

### Updating the Application

1. Make your changes and commit them to the repository
2. Run the deployment script again:
   ```bash
   ./deploy.sh
   ```

## Troubleshooting

- **Connection Issues**: Ensure security groups allow traffic on required ports (22, 80, 3000, 5432, 27017)
- **Docker Issues**: Try rebuilding the containers with `docker-compose build --no-cache`
- **Database Connection Issues**: Verify database credentials and network connectivity

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
