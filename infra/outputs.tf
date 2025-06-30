output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "ssh_connection_command" {
  description = "Command to SSH into the EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip}"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.app.public_ip}"
}

output "application_health_check" {
  description = "URL to check application health"
  value       = "http://${aws_instance.app.public_ip}/api/health"
}

# Database connection details (marked as sensitive)
output "postgres_connection" {
  description = "PostgreSQL connection details"
  value = {
    host     = aws_instance.app.public_ip
    port     = 5432
    database = var.db_name
    username = var.db_username
    # Password is not shown in output for security
  }
  sensitive = true
}

output "mysql_connection" {
  description = "MySQL connection details"
  value = {
    host     = aws_instance.app.public_ip
    port     = 3306
    database = var.mysql_database
    username = var.mysql_username
    # Password is not shown in output for security
  }
  sensitive = true
}

output "mongodb_connection" {
  description = "MongoDB connection details"
  value = {
    host     = aws_instance.app.public_ip
    port     = 27017
    database = var.mongodb_name
    username = var.mongodb_username
    # Password is not shown in output for security
  }
  sensitive = true
}

output "deployment_instructions" {
  description = "Instructions for accessing the deployed application"
  value = <<-EOT
    
    ===========================================================
    Deployment Successful!
    ===========================================================
    
    Application URL: http://${aws_instance.app.public_ip}
    SSH Access: ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip}
    
    Database Connections:
    - PostgreSQL: ${aws_instance.app.public_ip}:5432
    - MySQL: ${aws_instance.app.public_ip}:3306
    - MongoDB: ${aws_instance.app.public_ip}:27017
    
    Health Check: http://${aws_instance.app.public_ip}/api/health
    
    Note: Database credentials are stored in the .env file on the EC2 instance.
    For security, please change all default passwords after first login.
    ===========================================================
  EOT
}

# Output the Docker Compose logs command for debugging
output "docker_logs_commands" {
  description = "Commands to view Docker container logs"
  value = <<-EOT
    # View all container logs:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip} "cd /app && docker-compose logs -f"
    
    # View application logs:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip} "docker logs ${var.project_name}-app"
    
    # View database logs:
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip} "docker logs ${var.project_name}-postgres"
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip} "docker logs ${var.project_name}-mysql"
    ssh -i ${var.key_name}.pem ubuntu@${aws_instance.app.public_ip} "docker logs ${var.project_name}-mongodb"
  EOT
}
