# Security Group for MongoDB EC2
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "Security group for MongoDB EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere (restrict this in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # MongoDB access from within VPC
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "MongoDB access from VPC"
  }
  
  # HTTP/HTTPS for package updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }
  
  # DNS for service discovery
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS outbound"
  }
  
  # NTP for time synchronization
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP outbound"
  }

  tags = {
    Name = "mongodb-sg"
    Environment = var.environment
    ManagedBy = "Terraform"
  }
}

# EBS Volume for MongoDB data
resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = aws_subnet.public[0].availability_zone
  size             = 20  # 20GB for image storage
  type             = "gp3"
  
  tags = {
    Name = "mongodb-data"
  }
}

# MongoDB EC2 Instance
resource "aws_instance" "mongodb" {
  ami                    = "ami-020cba7c55df1f615"  # Specific Ubuntu AMI
  instance_type          = "t2.medium"  # Medium instance for better performance with MongoDB
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  subnet_id              = aws_subnet.public[0].id  # Use the first public subnet
  
  # Root volume configuration
  root_block_device {
    volume_size = 30  # 30GB root volume
    volume_type = "gp3"
  }
  
  # User data script to install and configure MongoDB with EBS volume
  user_data = <<-EOF
              #!/bin/bash
              # Update and install required packages
              apt-get update -y
              apt-get install -y xfsprogs
              
              # Format and mount the EBS volume
              mkfs -t xfs /dev/nvme1n1
              mkdir -p /data
              mount /dev/nvme1n1 /data
              
              # Add to fstab for persistence
              echo '/dev/nvme1n1 /data xfs defaults,nofail 0 2' >> /etc/fstab
              
              # Create MongoDB data directory
              mkdir -p /data/db
              chmod 755 /data/db
              
              # Install MongoDB
              wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
              echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
              apt-get update
              apt-get install -y mongodb-org
              
              # Configure MongoDB
              sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
              sed -i 's#dbPath: /var/lib/mongodb#dbPath: /data/db#' /etc/mongod.conf
              
              # Enable and start MongoDB
              systemctl enable mongod
              systemctl start mongod
              
              # Wait for MongoDB to start
              sleep 10
              
              # Create admin user and database
              mongo admin --eval '
                db.getSiblingDB("admin").createUser({
                  user: "${var.mongodb_username}",
                  pwd: "${var.mongodb_password}",
                  roles: ["root"]
                })'
                
              # Enable authentication
              sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
              
              # Restart MongoDB with authentication
              systemctl restart mongod
              
              # Create application database and user
              mongo admin -u ${var.mongodb_username} -p ${var.mongodb_password} --authenticationDatabase admin --eval '
                db = db.getSiblingDB("catalog");
                db.createUser({
                  user: "catalog_user",
                  pwd: "catalog_password",
                  roles: [{ role: "readWrite", db: "catalog" }]
                });
                
                // Create collections for images
                db.createCollection("product_images");
                db.createCollection("category_images");
                
                // Create indexes
                db.product_images.createIndex({ product_id: 1 });
                db.category_images.createIndex({ category_id: 1 });
              '
              EOF
              
  tags = {
    Name = "infradm-mongodb"
  }
}

# Attach EBS volume to MongoDB instance
resource "aws_volume_attachment" "mongodb_ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.mongodb_data.id
  instance_id = aws_instance.mongodb.id
  
  # Ensure the instance is running before attaching the volume
  depends_on = [aws_instance.mongodb]
}

# Using specific AMI: ami-020cba7c55df1f615

# Outputs
output "mongodb_instance_public_dns" {
  value = aws_instance.mongodb.public_dns
}

output "mongodb_connection_string" {
  value       = "mongodb://${var.mongodb_username}:${var.mongodb_password}@${aws_instance.mongodb.public_dns}:27017/catalog?authSource=admin"
  description = "MongoDB connection string with credentials"
  sensitive   = true
}
