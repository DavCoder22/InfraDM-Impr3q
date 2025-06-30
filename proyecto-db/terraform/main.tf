# Provider configuration
provider "aws" {
  region                  = var.region
  shared_config_files      = ["C:\\Users\\david\\.aws\\config"]
  shared_credentials_files = ["C:\\Users\\david\\.aws\\credentials"]
  
  # Optional: Add a default tags block for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "infradm-vpc"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "infradm-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name        = "infradm-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Security Group for Databases
resource "aws_security_group" "db_sg" {
  name        = "infradm-db-sg"
  description = "Security group for database instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }


  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }


  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Redis Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "infradm-redis-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

# Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "infradm-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name  = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  security_group_ids   = [aws_security_group.db_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
}

# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "mongodb" {
  name       = "infradm-mongodb-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

# DocumentDB Cluster (MongoDB compatible)
resource "aws_docdb_cluster" "mongodb" {
  cluster_identifier   = "infradm-mongodb-cluster"
  engine               = "docdb"
  master_username      = var.mongodb_username
  master_password      = var.mongodb_password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_docdb_subnet_group.mongodb.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

# DocumentDB Cluster Instance
resource "aws_docdb_cluster_instance" "mongodb" {
  count              = 1
  identifier         = "infradm-mongodb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.mongodb.id
  instance_class     = "db.t3.medium"
}

# RDS for MySQL
resource "aws_db_instance" "mysql" {
  identifier           = "infradm-mysql"
  engine               = "mysql"
  engine_version       = "8.0.32"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = var.mysql_username
  password             = var.mysql_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

# RDS for PostgreSQL
resource "aws_db_instance" "postgresql" {
  identifier           = "infradm-postgresql"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = var.postgres_username
  password             = var.postgres_password
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

# DB Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "infradm-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "infradm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "infradm-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "infradm-api"
  protocol_type = "HTTP"
  description   = "API Gateway for InfraDM application"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "mongodb_endpoint" {
  value = aws_docdb_cluster.mongodb.endpoint
}

output "mysql_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "postgresql_endpoint" {
  value = aws_db_instance.postgresql.endpoint
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}
