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

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
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

# API Gateway variables
variable "api_gateway_instance_type" {
  description = "Instance type for API Gateway"
  type        = string
  default     = "t3.small"
}

variable "api_gateway_desired_capacity" {
  description = "Desired capacity for API Gateway ASG"
  type        = number
  default     = 1
}

variable "api_gateway_min_size" {
  description = "Minimum size for API Gateway ASG"
  type        = number
  default     = 1
}

variable "api_gateway_max_size" {
  description = "Maximum size for API Gateway ASG"
  type        = number
  default     = 3
}

# Microservices variables
variable "microservices_instance_type" {
  description = "Instance type for microservices"
  type        = string
  default     = "t3.micro"
}

variable "microservices_desired_capacity" {
  description = "Desired capacity for microservices ASG"
  type        = number
  default     = 1
}

variable "microservices_min_size" {
  description = "Minimum size for microservices ASG"
  type        = number
  default     = 1
}

variable "microservices_max_size" {
  description = "Maximum size for microservices ASG"
  type        = number
  default     = 5
}

variable "microservices_count" {
  description = "Number of microservices to deploy"
  type        = number
  default     = 5
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

# Redis variables
variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = "change-me-please"
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

# Monitoring variables
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_dashboard" {
  description = "Enable CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

# Site24x7 integration variables
variable "site24x7_enabled" {
  description = "Enable Site24x7 monitoring"
  type        = bool
  default     = true
}

variable "site24x7_agent_key" {
  description = "Site24x7 agent key"
  type        = string
  sensitive   = true
  default     = ""
}

# Grafana integration variables
variable "grafana_enabled" {
  description = "Enable Grafana monitoring"
  type        = bool
  default     = true
}

variable "grafana_endpoint" {
  description = "Grafana endpoint URL"
  type        = string
  default     = ""
}

variable "grafana_api_key" {
  description = "Grafana API key"
  type        = string
  sensitive   = true
  default     = ""
}
