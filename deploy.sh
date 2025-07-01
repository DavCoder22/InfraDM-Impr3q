#!/bin/bash
set -e

# Configuration
PROJECT_NAME="${PROJECT_NAME:-infradm}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y jq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        echo "Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
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

# Get the ALB DNS name and instance IP
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Function to check health endpoint
check_health_endpoint() {
    local url=$1
    local max_attempts=10
    local attempt=1
    local status_code=0

    echo -e "${YELLOW}Checking health endpoint at $url...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        status_code=$(curl -s -o /dev/null -w "%{http_code}" $url || true)
        
        if [[ "$status_code" =~ ^(200|201|204|301|302|304)$ ]]; then
            echo -e "${GREEN}Health check passed with status code: $status_code${NC}"
            return 0
        else
            echo "Attempt $attempt/$max_attempts - Health check failed with status code: $status_code"
            sleep 10
            ((attempt++))
        fi
    done
    
    echo -e "${YELLOW}Health check failed after $max_attempts attempts.${NC}"
    return 1
}

# Check health endpoint on the instance directly
check_health_endpoint "http://$INSTANCE_IP/health"

# Check health endpoint through the ALB
if [ -n "$ALB_DNS_NAME" ]; then
    echo -e "\n${YELLOW}Waiting for ALB to become available...${NC}"
    # Wait for ALB to become available
    sleep 30
    
    echo -e "\n${YELLOW}Testing ALB endpoint...${NC}"
    check_health_endpoint "http://$ALB_DNS_NAME/health"
    
    echo -e "\n${GREEN}Deployment completed successfully!${NC}"
    echo -e "Instance URL: http://$INSTANCE_IP"
    echo -e "ALB URL: http://$ALB_DNS_NAME"
    
    # Get ALB target group health status
    echo -e "\n${YELLOW}Checking ALB target group health...${NC}"
    TARGET_GROUP_ARN=$(terraform output -raw target_group_arn)
    if [ -n "$TARGET_GROUP_ARN" ]; then
        aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN \
            --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
            --output table
    fi
else
    echo -e "\n${YELLOW}ALB DNS name not found. Please check the ALB configuration.${NC}"
    echo -e "Instance URL: http://$INSTANCE_IP"
fi

# Deploy the application
echo "Deploying the application..."
scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -r ../* ubuntu@${INSTANCE_IP}:/app
ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ubuntu@${INSTANCE_IP} "cd /app && docker-compose up -d"

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
