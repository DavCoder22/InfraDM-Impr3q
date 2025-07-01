terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    # This will be configured when setting up the S3 backend
    # bucket = "your-terraform-state-bucket"
    # key    = "infra/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Allow all outbound traffic
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

# Security Group for EC2 instances
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Allow HTTP from ALB
  ingress {
    from_port       = 80  # Puerto HTTP estándar
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow HTTP from anywhere (temporal para pruebas)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Create VPC with a single public subnet
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create public route table
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

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create security group for EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance with all services"
  vpc_id      = aws_vpc.main.id
  
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }
  
  # Node.js app port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Node.js app access"
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Create EC2 instance
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address  = true
  
  # Use a larger root volume for database storage
  root_block_device {
    volume_size = 50  # 50GB for databases and application
    volume_type = "gp3"
    encrypted   = true
  }
  
  # User data script to install Docker, Docker Compose, and set up the application
  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update and install required packages
              apt-get update -y
              DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
              apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                software-properties-common \
                git \
                nginx \
                ufw
              
              # Configure UFW firewall
              ufw --force enable
              ufw allow ssh
              ufw allow http
              ufw allow https
              ufw allow 3000/tcp
              
              # Install Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo \
                "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" \
                -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Add ubuntu user to docker group
              usermod -aG docker ubuntu
              
              # Create application directory
              mkdir -p /app
              
              # Create .env file with environment variables
              cat > /app/.env << 'EOL'
              # Application
              NODE_ENV=production
              PORT=3000
              JWT_SECRET=${var.jwt_secret}
              
              # PostgreSQL
              POSTGRES_HOST=postgres
              POSTGRES_PORT=5432
              POSTGRES_USER=${var.db_username}
              POSTGRES_PASSWORD=${var.db_password}
              POSTGRES_DB=${var.db_name}
              
              # MySQL
              MYSQL_HOST=mysql
              MYSQL_PORT=3306
              MYSQL_USER=${var.mysql_username}
              MYSQL_PASSWORD=${var.mysql_password}
              MYSQL_DATABASE=${var.mysql_database}
              MYSQL_ROOT_PASSWORD=${var.mysql_root_password}
              
              # MongoDB
              MONGODB_URI=mongodb://${var.mongodb_username}:${var.mongodb_password}@mongodb:27017/${var.mongodb_name}?authSource=admin
              MONGO_INITDB_ROOT_USERNAME=${var.mongodb_username}
              MONGO_INITDB_ROOT_PASSWORD=${var.mongodb_password}
              MONGO_INITDB_DATABASE=${var.mongodb_name}
              
              # AWS
              AWS_ACCESS_KEY_ID=${var.aws_access_key_id}
              AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}
              AWS_REGION=${var.aws_region}
              EOL
              
              # Create docker-compose.yml
              cat > /app/docker-compose.yml << 'EOL'
              version: '3.8'
              
              services:
                app:
                  build:
                    context: .
                    dockerfile: Dockerfile
                  container_name: ${var.project_name}-app
                  restart: always
                  ports:
                    - "3000:3000"
                  env_file:
                    - .env
                  depends_on:
                    postgres:
                      condition: service_healthy
                    mysql:
                      condition: service_healthy
                    mongodb:
                      condition: service_healthy
                  networks:
                    - app-network
                
                # PostgreSQL database
                postgres:
                  image: postgres:14-alpine
                  container_name: ${var.project_name}-postgres
                  restart: always
                  env_file:
                    - .env
                  environment:
                    - POSTGRES_USER=${var.db_username}
                    - POSTGRES_PASSWORD=${var.db_password}
                    - POSTGRES_DB=${var.db_name}
                  volumes:
                    - postgres_data:/var/lib/postgresql/data
                  healthcheck:
                    test: ["CMD-SHELL", "pg_isready -U ${var.db_username} -d ${var.db_name}"]
                    interval: 5s
                    timeout: 5s
                    retries: 5
                  networks:
                    - app-network
                
                # MySQL database
                mysql:
                  image: mysql:8.0
                  container_name: ${var.project_name}-mysql
                  restart: always
                  env_file:
                    - .env
                  environment:
                    - MYSQL_ROOT_PASSWORD=${var.mysql_root_password}
                    - MYSQL_DATABASE=${var.mysql_database}
                    - MYSQL_USER=${var.mysql_username}
                    - MYSQL_PASSWORD=${var.mysql_password}
                  volumes:
                    - mysql_data:/var/lib/mysql
                  command: --default-authentication-plugin=mysql_native_password
                  healthcheck:
                    test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u${var.mysql_username}", "-p${var.mysql_password}"]
                    interval: 5s
                    timeout: 5s
                    retries: 5
                  networks:
                    - app-network
                
                # MongoDB
                mongodb:
                  image: mongo:5.0
                  container_name: ${var.project_name}-mongodb
                  restart: always
                  env_file:
                    - .env
                  environment:
                    - MONGO_INITDB_ROOT_USERNAME=${var.mongodb_username}
                    - MONGO_INITDB_ROOT_PASSWORD=${var.mongodb_password}
                    - MONGO_INITDB_DATABASE=${var.mongodb_name}
                  volumes:
                    - mongodb_data:/data/db
                  healthcheck:
                    test: echo 'db.runCommand("ping").ok' | mongosh --quiet "mongodb://${var.mongodb_username}:${var.mongodb_password}@localhost:27017/${var.mongodb_name}?authSource=admin" --eval ""
                    interval: 10s
                    timeout: 5s
                    retries: 5
                  networks:
                    - app-network
                
                # Nginx reverse proxy
                nginx:
                  image: nginx:alpine
                  container_name: ${var.project_name}-nginx
                  restart: always
                  ports:
                    - "80:80"
                    - "443:443"
                  volumes:
                    - ./nginx/nginx.conf:/etc/nginx/nginx.conf
                    - ./nginx/conf.d:/etc/nginx/conf.d
                    - ./certs:/etc/letsencrypt
                  depends_on:
                    - app
                  networks:
                    - app-network
              
              volumes:
                postgres_data:
                mysql_data:
                mongodb_data:
              
              networks:
                app-network:
                  driver: bridge
              EOL
              
              # Create nginx configuration directory
              mkdir -p /app/nginx/conf.d
              
              # Create nginx configuration
              cat > /etc/nginx/sites-available/${var.project_name} << 'NGINX_CONF'
              server {
                  listen 80;
                  server_name _;
                  
                  # Health check endpoint
                  location = /health {
                      access_log off;
                      add_header Content-Type application/json;
                      
                      # Default response
                      set $status 'OK';
                      set $response '"status": "OK"';
                      
                      # Check PostgreSQL connection
                      if ($request_uri ~* "check=postgresql" || $request_uri = /health) {
                          set $pg_status "";
                          content_by_lua_block {
                              local cjson = require "cjson"
                              local pg = require "pgmoon"
                              local db = pg:new()
                              
                              local response = { status = "OK" }
                              
                              -- PostgreSQL check
                              local ok, err = db:connect({
                                  host = "postgres",
                                  port = 5432,
                                  database = "${var.db_name}",
                                  user = "${var.db_username}",
                                  password = "${var.db_password}",
                                  ssl = false
                              })
                              
                              if not ok then
                                  response.postgresql = "error"
                                  response.postgresql_error = tostring(err)
                                  ngx.status = 503
                                  response.status = "ERROR"
                              else
                                  response.postgresql = "ok"
                                  db:keepalive()
                              end
                              
                              -- Return JSON response
                              ngx.say(cjson.encode(response))
                          }
                      }
                      
                      # Simple health check without DB checks
                      if ($request_uri !~* "check=") {
                          return 200 '{"status": "OK"}';
                      }
                  }
                  
                  # Proxy pass to the application
                  location / {
                      proxy_pass http://127.0.0.1:3000;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto $scheme;
                      proxy_cache_bypass $http_upgrade;
                  }
              }
              NGINX_CONF
              
              # Create certs directory for SSL certificates (for future use)
              mkdir -p /app/certs
              
              # Set permissions
              chown -R ubuntu:ubuntu /app
              chmod -R 755 /app
              
              # Start services with Docker Compose
              cd /app
              docker-compose up --build -d
              
              # Set up automatic updates (optional)
              (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/docker system prune -af --volumes") | crontab -
              (crontab -l 2>/dev/null; echo "0 4 * * * /usr/bin/docker-compose -f /app/docker-compose.yml pull && /usr/bin/docker-compose -f /app/docker-compose.yml up -d --build") | crontab -
}
NGINX_CONF

              # Enable the site
              ln -sf /etc/nginx/sites-available/${var.project_name} /etc/nginx/sites-enabled/
              rm -f /etc/nginx/sites-enabled/default
              
              # Test and restart Nginx
              nginx -t
              systemctl restart nginx
              
              # Install and configure UFW (firewall)
              apt-get install -y ufw
              ufw allow OpenSSH
              ufw allow 'Nginx Full'
              ufw --force enable
              
              # Print completion message
              echo "Setup completed successfully!"
              EOF
  
  tags = {
    Name        = "${var.project_name}-app-server"
    Environment = var.environment
  }
  
  # Ensure enough time for the instance to be ready
  timeouts {
    create = "10m"
    delete = "30m"
  }
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  owners = ["099720109477"] # Canonical
}

# Outputs
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app_server.public_ip}"
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id]  # Usando la subred pública existente

  enable_deletion_protection = false  # Cambiar a true en producción

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group para el microservicio principal
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-main-tg"
  port        = 80  # Puerto HTTP estándar
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"  # Ruta de health check
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }


  tags = {
    Name = "${var.project_name}-main-tg"
  }
}

# Registrar instancia EC2 en el target group
resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.app.id
  port             = 80  # Puerto HTTP estándar
}

# Listener HTTP (redirige a HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
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

# Outputs adicionales para el ALB
output "alb_dns_name" {
  description = "DNS name del ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del ALB"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN del target group principal"
  value       = aws_lb_target_group.main.arn
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.app_server.public_ip}"
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}
