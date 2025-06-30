# InfraDM - Infrastructure as Code

This project sets up a complete infrastructure with multiple databases, Redis for billing/administration, and MongoDB for catalog images, along with AWS resources for deployment.

## Prerequisites

1. Docker and Docker Compose
2. AWS CLI configured with appropriate credentials
3. Terraform (v1.0.0 or later)
4. Make (optional, for convenience commands)

## Local Development

### 1. Set up environment variables

Copy the example environment file and update the values:

```bash
cp .env.example .env
```

Edit the `.env` file with your desired credentials.

### 2. Start services

Start all services using Docker Compose:

```bash
docker-compose up -d
```

This will start:
- MySQL on port 3306
- PostgreSQL on port 5432
- Redis on port 6379
- MongoDB on port 27017

### 3. Verify services

Check that all services are running:

```bash
docker-compose ps
```

## AWS Deployment

### 1. Configure AWS

Ensure you have AWS CLI configured with the appropriate credentials:

```bash
aws configure
```

### 2. Initialize Terraform

Navigate to the terraform directory and initialize:

```bash
cd terraform
terraform init
```

### 3. Review the plan

```bash
terraform plan
```

### 4. Apply the configuration

```bash
terraform apply
```

This will create:
- VPC and subnets
- Security groups
- RDS instances for MySQL and PostgreSQL
- ElastiCache for Redis
- DocumentDB for MongoDB
- Application Load Balancer
- API Gateway

## Service Endpoints

After deployment, you can access the following services:

- **MySQL**: `mysql://<rds-endpoint>:3306`
- **PostgreSQL**: `postgresql://<rds-endpoint>:5432`
- **Redis**: `redis://<elasticache-endpoint>:6379`
- **MongoDB**: `mongodb://<docdb-endpoint>:27017`
- **API Gateway**: `https://<api-gateway-id>.execute-api.<region>.amazonaws.com`

## Security Notes

1. Always use strong, unique passwords for all services
2. Restrict access to database instances using security groups
3. Enable encryption at rest and in transit for all services
4. Regularly rotate database credentials

## Cleanup

To destroy all AWS resources:

```bash
cd terraform
terraform destroy
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
