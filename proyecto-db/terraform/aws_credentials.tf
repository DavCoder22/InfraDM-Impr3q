# MySQL EC2 Instance
resource "aws_instance" "mysql" {
  ami           = "ami-020cba7c55df1f615"  # Specific Ubuntu AMI
  instance_type = "t2.micro"  # Free tier eligible
  subnet_id     = aws_subnet.public[0].id  # Use the first public subnet
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.mysql.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y mysql-server
    mysql -e "CREATE DATABASE ${var.mysql_database};"
    mysql -e "CREATE USER '${var.mysql_user}'@'%' IDENTIFIED BY '${var.mysql_password}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${var.mysql_database}.* TO '${var.mysql_user}'@'%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Configurar MySQL para permitir conexiones remotas
    sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    systemctl restart mysql
  EOF

  tags = {
    Name = "mysql-ec2"
  }
}

# PostgreSQL EC2 Instance
resource "aws_instance" "postgres" {
  ami           = "ami-020cba7c55df1f615"  # Specific Ubuntu AMI
  instance_type = "t2.micro"  # Free tier eligible
  subnet_id     = aws_subnet.public[1].id  # Use the second public subnet
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y postgresql postgresql-contrib
    
    # Crear base de datos y usuario
    sudo -u postgres psql -c "CREATE DATABASE ${var.postgres_db};"
    sudo -u postgres psql -c "CREATE USER ${var.postgres_user} WITH PASSWORD '${var.postgres_password}';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${var.postgres_db} TO ${var.postgres_user};"
    
    # Configurar PostgreSQL para permitir conexiones remotas
    echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/14/main/postgresql.conf
    echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/14/main/pg_hba.conf
    systemctl restart postgresql
  EOF

  tags = {
    Name = "postgres-ec2"
  }
}

# Security Groups
resource "aws_security_group" "mysql" {
  name        = "mysql-sg"
  description = "Security group for MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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

resource "aws_security_group" "postgres" {
  name        = "postgres-sg"
  description = "Security group for PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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