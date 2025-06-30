variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "infradm"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

# PostgreSQL variables
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "catalogodb"
}

variable "db_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

# MySQL variables
variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "catalogodb"
}

variable "mysql_username" {
  description = "MySQL username"
  type        = string
  default     = "mysql"
}

variable "mysql_password" {
  description = "MySQL password"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
  default     = "change-me-please"
}

# MongoDB variables
variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
  default     = "mongodb"
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
}

variable "mongodb_name" {
  description = "MongoDB database name"
  type        = string
  default     = "catalogodb"
}

# Application variables
variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "change-me-to-a-secure-secret"
}

# AWS credentials (for application use)
variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
  default     = ""
}
