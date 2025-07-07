terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    # Configurar cuando se tenga el bucket S3
    # bucket = "infradm-terraform-state"
    # key    = "infra/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# VPC Y NETWORKING
# =============================================================================

# VPC principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Subnets públicas (múltiples AZ para alta disponibilidad)
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# Subnets privadas para las bases de datos
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Tier = "Private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# NAT Gateway (para instancias privadas)
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Security Group para ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Health checks
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Health check port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Security Group para NLB
resource "aws_security_group" "nlb" {
  name        = "${var.project_name}-nlb-sg"
  description = "Security group for Network Load Balancer"
  vpc_id      = aws_vpc.main.id

  # HTTP para microservicios
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for microservices"
  }

  # Puerto para microservicios específicos
  ingress {
    from_port   = 3000
    to_port     = 3010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Microservices ports range"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-nlb-sg"
  }
}

# Security Group para EC2 instances (API Gateway)
resource "aws_security_group" "api_gateway" {
  name        = "${var.project_name}-api-gateway-sg"
  description = "Security group for API Gateway instances"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP desde ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from ALB"
  }

  # Puerto de la aplicación
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "App port from ALB"
  }

  # Puerto para health checks
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Health check from ALB"
  }

  # Acceso a microservicios
  ingress {
    from_port   = 3000
    to_port     = 3010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Microservices communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-api-gateway-sg"
  }
}

# Security Group para microservicios
resource "aws_security_group" "microservices" {
  name        = "${var.project_name}-microservices-sg"
  description = "Security group for microservices instances"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP desde NLB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
    description     = "HTTP from NLB"
  }

  # Puertos de microservicios
  ingress {
    from_port       = 3000
    to_port         = 3010
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
    description     = "Microservices ports from NLB"
  }

  # Comunicación entre microservicios
  ingress {
    from_port       = 3000
    to_port         = 3010
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices.id]
    description     = "Inter-microservice communication"
  }

  # Puerto para health checks
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
    description     = "Health check from NLB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-microservices-sg"
  }
}

# Security Group para bases de datos
resource "aws_security_group" "databases" {
  name        = "${var.project_name}-databases-sg"
  description = "Security group for database instances"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway.id, aws_security_group.microservices.id]
    description     = "PostgreSQL access"
  }

  # MySQL
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway.id, aws_security_group.microservices.id]
    description     = "MySQL access"
  }

  # MongoDB
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway.id, aws_security_group.microservices.id]
    description     = "MongoDB access"
  }

  # Redis
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway.id, aws_security_group.microservices.id]
    description     = "Redis access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-databases-sg"
  }
}

# =============================================================================
# LOAD BALANCERS
# =============================================================================

# Application Load Balancer para API Gateway
resource "aws_lb" "api_gateway" {
  name               = "${var.project_name}-api-gateway-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "api-gateway"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-api-gateway-alb"
  }
}

# Network Load Balancer para microservicios
resource "aws_lb" "microservices" {
  name               = "${var.project_name}-microservices-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-microservices-nlb"
  }
}

# =============================================================================
# TARGET GROUPS
# =============================================================================

# Target Group para API Gateway
resource "aws_lb_target_group" "api_gateway" {
  name        = "${var.project_name}-api-gateway-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-api-gateway-tg"
  }
}

# Target Groups para microservicios (ejemplo para 5 servicios)
resource "aws_lb_target_group" "microservices" {
  count       = 5
  name        = "${var.project_name}-microservice-${count.index + 1}-tg"
  port        = 3000 + count.index
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "TCP"
  }

  tags = {
    Name = "${var.project_name}-microservice-${count.index + 1}-tg"
  }
}

# =============================================================================
# LISTENERS
# =============================================================================

# Listener HTTP para API Gateway
resource "aws_lb_listener" "api_gateway_http" {
  load_balancer_arn = aws_lb.api_gateway.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener HTTPS para API Gateway (placeholder)
resource "aws_lb_listener" "api_gateway_https" {
  load_balancer_arn = aws_lb.api_gateway.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }
}

# Listeners para microservicios
resource "aws_lb_listener" "microservices" {
  count             = 5
  load_balancer_arn = aws_lb.microservices.arn
  port              = 3000 + count.index
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservices[count.index].arn
  }
}

# =============================================================================
# AUTO SCALING GROUPS
# =============================================================================

# Launch Template para API Gateway
resource "aws_launch_template" "api_gateway" {
  name_prefix   = "${var.project_name}-api-gateway-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.api_gateway_instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.api_gateway.id]
  }

  key_name = var.key_name

  user_data = base64encode(templatefile("${path.module}/user_data/api_gateway.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.api_gateway.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-api-gateway"
      Role = "api-gateway"
    }
  }
}

# Launch Template para microservicios
resource "aws_launch_template" "microservices" {
  name_prefix   = "${var.project_name}-microservices-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.microservices_instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.microservices.id]
  }

  key_name = var.key_name

  user_data = base64encode(templatefile("${path.module}/user_data/microservices.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.microservices.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-microservice"
      Role = "microservice"
    }
  }
}

# Auto Scaling Group para API Gateway
resource "aws_autoscaling_group" "api_gateway" {
  name                = "${var.project_name}-api-gateway-asg"
  desired_capacity    = var.api_gateway_desired_capacity
  max_size           = var.api_gateway_max_size
  min_size           = var.api_gateway_min_size
  target_group_arns  = [aws_lb_target_group.api_gateway.arn]
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.api_gateway.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.project_name}-api-gateway"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value              = "api-gateway"
    propagate_at_launch = true
  }
}

# Auto Scaling Group para microservicios
resource "aws_autoscaling_group" "microservices" {
  count               = 5
  name                = "${var.project_name}-microservice-${count.index + 1}-asg"
  desired_capacity    = var.microservices_desired_capacity
  max_size           = var.microservices_max_size
  min_size           = var.microservices_min_size
  target_group_arns  = [aws_lb_target_group.microservices[count.index].arn]
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.microservices.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.project_name}-microservice-${count.index + 1}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value              = "microservice"
    propagate_at_launch = true
  }
}

# =============================================================================
# IAM ROLES
# =============================================================================

# IAM Role para API Gateway
resource "aws_iam_role" "api_gateway" {
  name = "${var.project_name}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role para microservicios
resource "aws_iam_role" "microservices" {
  name = "${var.project_name}-microservices-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Instance Profiles
resource "aws_iam_instance_profile" "api_gateway" {
  name = "${var.project_name}-api-gateway-profile"
  role = aws_iam_role.api_gateway.name
}

resource "aws_iam_instance_profile" "microservices" {
  name = "${var.project_name}-microservices-profile"
  role = aws_iam_role.microservices.name
}

# =============================================================================
# S3 BUCKET PARA LOGS
# =============================================================================

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# CLOUDWATCH Y MONITORING
# =============================================================================

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/ec2/${var.project_name}-api-gateway"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "microservices" {
  name              = "/aws/ec2/${var.project_name}-microservices"
  retention_in_days = 7
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.api_gateway.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Load Balancer Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.api_gateway.name],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupTotalInstances", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Auto Scaling Group Metrics"
        }
      }
    ]
  })
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Random string para nombres únicos
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
