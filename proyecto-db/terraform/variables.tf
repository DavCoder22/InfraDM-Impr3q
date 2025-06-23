# -------------------------------
# Región y clave SSH
# -------------------------------
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH access"
  type        = string
  default     = "pc1"
}

# -------------------------------
# Red: VPC y Subnets
# -------------------------------
variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
  default     = "vpc-06eaaae70c3e6b168"
}

variable "subnet_ids" {
  description = "List of subnet IDs (e.g., [MySQL Subnet, PostgreSQL Subnet])"
  type        = list(string)
  default     = ["subnet-0cc3999a4d53e28a3", "subnet-0e9d4abfab26edfd2"]
}

# -------------------------------
# MySQL Configuration
# -------------------------------
variable "mysql_root_password" {
  description = "Root password for MySQL"
  type        = string
  sensitive   = true
  default     = "Sebasalejandro22"
}

variable "mysql_database" {
  description = "Name of the MySQL database"
  type        = string
  default     = "mydb"
}

variable "mysql_user" {
  description = "Username for the MySQL database"
  type        = string
  default     = "admin"
}

variable "mysql_password" {
  description = "Password for the MySQL user"
  type        = string
  sensitive   = true
  default     = "Sebasalejandro22"
}

# -------------------------------
# PostgreSQL Configuration
# -------------------------------
variable "postgres_db" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "postgresdb"
}

variable "postgres_user" {
  description = "Username for the PostgreSQL database"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "Password for the PostgreSQL user"
  type        = string
  sensitive   = true
  default     = "Sebasalejandro22"
}
