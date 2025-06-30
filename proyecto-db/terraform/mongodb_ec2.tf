# Security Group para MongoDB
resource "aws_security_group" "mongodb_sg" {
  name        = "infradm-mongodb-sg"
  description = "Security group for MongoDB EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere (limitar a tu IP en producción)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MongoDB access from anywhere (limitar a tu IP o VPC en producción)
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "infradm-mongodb-sg"
  }
}

# Instancia EC2 para MongoDB
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  subnet_id              = aws_subnet.public[0].id  # Usar la primera subnet pública
  
  # Script de inicialización
  user_data = <<-EOF
              #!/bin/bash
              # Actualizar e instalar Docker
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io
              
              # Crear directorio para datos de MongoDB
              mkdir -p /data/db
              
              # Crear archivo de inicialización
              cat > /tmp/init-mongo.js << 'EOL'
              // Initialize MongoDB with a catalog database and user
              db = db.getSiblingDB('catalog');

              // Create a user for the catalog database
              db.createUser({
                user: 'catalog_user',
                pwd: 'catalog_password',
                roles: [
                  {
                    role: 'readWrite',
                    db: 'catalog'
                  }
                ]
              });

              // Create collections for catalog images
              db.createCollection('product_images');
              db.createCollection('category_images');

              // Create indexes for better query performance
              db.product_images.createIndex({ product_id: 1 });
              db.category_images.createIndex({ category_id: 1 });
              EOL

              # Ejecutar MongoDB en un contenedor
              docker run -d \
                --name mongodb \
                -p 27017:27017 \
                -v /data/db:/data/db \
                -v /tmp/init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js \
                -e MONGO_INITDB_ROOT_USERNAME=${var.mongodb_username} \
                -e MONGO_INITDB_ROOT_PASSWORD=${var.mongodb_password} \
                -e MONGO_INITDB_DATABASE=admin \
                mongo:6
              EOF

  tags = {
    Name = "infradm-mongodb"
  }
}

# Datasource para la última AMI de Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Outputs
output "mongodb_instance_public_dns" {
  value = aws_instance.mongodb.public_dns
}

output "mongodb_connection_string" {
  value = "mongodb://${var.mongodb_username}:${var.mongodb_password}@${aws_instance.mongodb.public_dns}:27017/catalog?authSource=admin"
}
