# Provider configuration
provider "aws" {
  region  = var.region
  profile = "default"
  
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

# DB Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "infradm-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id
  
  tags = {
    Name = "Database Subnet Group"
  }
}

# RDS for MySQL
resource "aws_db_instance" "mysql" {
  identifier           = "infradm-mysql"
  engine               = "mysql"
  engine_version       = "8.0.32"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = var.mysql_user
  password             = var.mysql_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
  
  tags = {
    Name = "infradm-mysql"
  }
}

# RDS for PostgreSQL
resource "aws_db_instance" "postgresql" {
  identifier           = "infradm-postgresql"
  engine               = "postgres"
  engine_version       = "13.12"  # Updated to a stable version
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = var.postgres_user
  password             = var.postgres_password
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
  
  # Add these settings to ensure proper configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  multi_az               = false  # Set to true for production
  
  # Enable storage autoscaling
  max_allocated_storage = 100  # Maximum storage in GB to scale to
  
  # Enable performance insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  # Enable deletion protection in production
  deletion_protection = false  # Set to true for production
  
  tags = {
    Name = "infradm-postgresql"
  }
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

output "mysql_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "postgresql_endpoint" {
  value = aws_db_instance.postgresql.endpoint
}

output "mongodb_ec2_public_dns" {
  value = aws_instance.mongodb.public_dns
}
