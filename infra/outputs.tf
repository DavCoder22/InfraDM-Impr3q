# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# =============================================================================
# LOAD BALANCER OUTPUTS
# =============================================================================

output "api_gateway_alb_dns_name" {
  description = "DNS name of the API Gateway Application Load Balancer"
  value       = aws_lb.api_gateway.dns_name
}

output "api_gateway_alb_zone_id" {
  description = "Zone ID of the API Gateway Application Load Balancer"
  value       = aws_lb.api_gateway.zone_id
}

output "api_gateway_alb_arn" {
  description = "ARN of the API Gateway Application Load Balancer"
  value       = aws_lb.api_gateway.arn
}

output "microservices_nlb_dns_name" {
  description = "DNS name of the Microservices Network Load Balancer"
  value       = aws_lb.microservices.dns_name
}

output "microservices_nlb_zone_id" {
  description = "Zone ID of the Microservices Network Load Balancer"
  value       = aws_lb.microservices.zone_id
}

output "microservices_nlb_arn" {
  description = "ARN of the Microservices Network Load Balancer"
  value       = aws_lb.microservices.arn
}

# =============================================================================
# TARGET GROUP OUTPUTS
# =============================================================================

output "api_gateway_target_group_arn" {
  description = "ARN of the API Gateway target group"
  value       = aws_lb_target_group.api_gateway.arn
}

output "microservices_target_group_arns" {
  description = "ARNs of the microservices target groups"
  value       = aws_lb_target_group.microservices[*].arn
}

# =============================================================================
# AUTO SCALING GROUP OUTPUTS
# =============================================================================

output "api_gateway_asg_name" {
  description = "Name of the API Gateway Auto Scaling Group"
  value       = aws_autoscaling_group.api_gateway.name
}

output "api_gateway_asg_arn" {
  description = "ARN of the API Gateway Auto Scaling Group"
  value       = aws_autoscaling_group.api_gateway.arn
}

output "microservices_asg_names" {
  description = "Names of the microservices Auto Scaling Groups"
  value       = aws_autoscaling_group.microservices[*].name
}

output "microservices_asg_arns" {
  description = "ARNs of the microservices Auto Scaling Groups"
  value       = aws_autoscaling_group.microservices[*].arn
}

# =============================================================================
# SECURITY GROUP OUTPUTS
# =============================================================================

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "nlb_security_group_id" {
  description = "ID of the NLB security group"
  value       = aws_security_group.nlb.id
}

output "api_gateway_security_group_id" {
  description = "ID of the API Gateway security group"
  value       = aws_security_group.api_gateway.id
}

output "microservices_security_group_id" {
  description = "ID of the microservices security group"
  value       = aws_security_group.microservices.id
}

output "databases_security_group_id" {
  description = "ID of the databases security group"
  value       = aws_security_group.databases.id
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "api_gateway_iam_role_arn" {
  description = "ARN of the API Gateway IAM role"
  value       = aws_iam_role.api_gateway.arn
}

output "microservices_iam_role_arn" {
  description = "ARN of the microservices IAM role"
  value       = aws_iam_role.microservices.arn
}

# =============================================================================
# S3 OUTPUTS
# =============================================================================

output "alb_logs_bucket_name" {
  description = "Name of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.arn
}

# =============================================================================
# CLOUDWATCH OUTPUTS
# =============================================================================

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "api_gateway_log_group_name" {
  description = "Name of the API Gateway CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "microservices_log_group_name" {
  description = "Name of the microservices CloudWatch log group"
  value       = aws_cloudwatch_log_group.microservices.name
}

# =============================================================================
# APPLICATION URLS
# =============================================================================

output "api_gateway_url" {
  description = "URL to access the API Gateway"
  value       = "http://${aws_lb.api_gateway.dns_name}"
}

output "api_gateway_health_url" {
  description = "Health check URL for the API Gateway"
  value       = "http://${aws_lb.api_gateway.dns_name}/health"
}

output "microservices_urls" {
  description = "URLs to access the microservices"
  value = [
    for i in range(var.microservices_count) : "http://${aws_lb.microservices.dns_name}:${3000 + i}"
  ]
}

output "microservices_health_urls" {
  description = "Health check URLs for the microservices"
  value = [
    for i in range(var.microservices_count) : "http://${aws_lb.microservices.dns_name}:${3000 + i}/health"
  ]
}

# =============================================================================
# MONITORING ENDPOINTS
# =============================================================================

output "site24x7_monitoring_info" {
  description = "Information for Site24x7 monitoring setup"
  value = {
    enabled = var.site24x7_enabled
    endpoints = concat(
      [aws_lb.api_gateway.dns_name],
      [for i in range(var.microservices_count) : "${aws_lb.microservices.dns_name}:${3000 + i}"]
    )
    health_endpoints = concat(
      ["http://${aws_lb.api_gateway.dns_name}/health"],
      [for i in range(var.microservices_count) : "http://${aws_lb.microservices.dns_name}:${3000 + i}/health"]
    )
  }
}

output "grafana_monitoring_info" {
  description = "Information for Grafana monitoring setup"
  value = {
    enabled = var.grafana_enabled
    cloudwatch_dashboard = aws_cloudwatch_dashboard.main.dashboard_name
    log_groups = [
      aws_cloudwatch_log_group.api_gateway.name,
      aws_cloudwatch_log_group.microservices.name
    ]
  }
}

# =============================================================================
# AWS ACCOUNT INFO
# =============================================================================

data "aws_caller_identity" "current" {}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  description = "ARN of the current caller"
  value       = data.aws_caller_identity.current.arn
}

output "caller_user" {
  description = "User ID of the current caller"
  value       = data.aws_caller_identity.current.user_id
}

# =============================================================================
# DEPLOYMENT INFO
# =============================================================================

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    project_name = var.project_name
    environment = var.environment
    region = var.aws_region
    vpc_id = aws_vpc.main.id
    api_gateway_url = "http://${aws_lb.api_gateway.dns_name}"
    microservices_count = var.microservices_count
    availability_zones = var.availability_zones
    instance_types = {
      api_gateway = var.api_gateway_instance_type
      microservices = var.microservices_instance_type
    }
    auto_scaling = {
      api_gateway = {
        min = var.api_gateway_min_size
        desired = var.api_gateway_desired_capacity
        max = var.api_gateway_max_size
      }
      microservices = {
        min = var.microservices_min_size
        desired = var.microservices_desired_capacity
        max = var.microservices_max_size
      }
    }
    monitoring = {
      cloudwatch_enabled = var.enable_cloudwatch_logs
      site24x7_enabled = var.site24x7_enabled
      grafana_enabled = var.grafana_enabled
    }
  }
}
