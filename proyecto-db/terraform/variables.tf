# Project Configuration
variable "environment" {
  description = "Environment (e.g., Production, Development, Staging)"
  type        = string
  default     = "Production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "InfraDM"
}

# AWS Configuration
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH access"
  type        = string
  default     = "infradm-key"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Database Configuration
# PostgreSQL Configuration
variable "postgres_user" {
  description = "Username for PostgreSQL database"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  description = "Password for PostgreSQL database"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "postgres_db" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "infradm_db"
}

# MySQL Configuration
variable "mysql_root_password" {
  description = "Root password for MySQL database"
  type        = string
  sensitive   = true
  default     = "ChangeMeRoot123!"
}

variable "mysql_user" {
  description = "Username for MySQL database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "mysql_password" {
  description = "Password for MySQL database"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "mysql_database" {
  description = "Name of the MySQL database"
  type        = string
  default     = "infradm_db"
}

# Redis Configuration
variable "redis_node_type" {
  description = "Instance type for Redis nodes"
  type        = string
  default     = "cache.t3.micro"
}

# MongoDB Configuration
variable "mongodb_username" {
  description = "Username for MongoDB database"
  type        = string
  default     = "mongoadmin"
  sensitive   = true
}

variable "mongodb_password" {
  description = "Password for MongoDB database"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "InfraDM"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}
