#!/bin/bash
set -e

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install it first."
    exit 1
fi

# Build Docker image
echo "Building Docker image..."
docker build -t ${PROJECT_NAME}:latest .

# Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Create ECR repository if it doesn't exist
echo "Creating ECR repository if it doesn't exist..."
aws ecr describe-repositories --repository-names ${PROJECT_NAME} || aws ecr create-repository --repository-name ${PROJECT_NAME}

# Tag and push the Docker image
echo "Tagging and pushing Docker image to ECR..."
docker tag ${PROJECT_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:latest

# Initialize Terraform
echo "Initializing Terraform..."
cd infra
terraform init

# Apply Terraform configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Get the public IP of the EC2 instance
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Deploy the application
echo "Deploying the application..."
scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -r ../* ubuntu@${INSTANCE_IP}:/app
ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} "cd /app && docker-compose up -d"

echo "Deployment completed successfully!"
echo "Application URL: http://${INSTANCE_IP}:3000"

# Print connection details
echo "\nConnection details:"
terraform output -json | jq -r '
  "PostgreSQL:",
  "  Host: " + .postgres_connection.value.endpoint,
  "  Database: " + .postgres_connection.value.database,
  "  Username: " + .postgres_connection.value.username,
  "\nMongoDB:",
  "  Host: " + .mongodb_connection.value.endpoint,
  "  Database: " + .mongodb_connection.value.database,
  "  Username: " + .mongodb_connection.value.username
'
