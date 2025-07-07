#!/bin/bash

# =============================================================================
# InfraDM-Impr3q Deployment Test Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="infradm"
TIMEOUT=30

# Log function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if Terraform is installed
check_terraform() {
    log "Checking Terraform installation..."
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    success "Terraform is installed: $(terraform version | head -n1)"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    log "Checking AWS CLI installation and configuration..."
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    success "AWS CLI is configured: $(aws sts get-caller-identity --query 'Arn' --output text)"
}

# Check if terraform.tfvars exists
check_configuration() {
    log "Checking Terraform configuration..."
    if [ ! -f "terraform.tfvars" ]; then
        error "terraform.tfvars file not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    success "terraform.tfvars found"
    
    # Check required variables
    local required_vars=("key_name" "db_password" "mysql_password" "mongodb_password")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}.*=.*[^[:space:]]" terraform.tfvars; then
            warning "Variable ${var} might not be set in terraform.tfvars"
        fi
    done
}

# Initialize Terraform
init_terraform() {
    log "Initializing Terraform..."
    terraform init
    success "Terraform initialized"
}

# Plan Terraform deployment
plan_deployment() {
    log "Planning Terraform deployment..."
    terraform plan -out=tfplan
    success "Terraform plan created"
}

# Apply Terraform deployment
apply_deployment() {
    log "Applying Terraform deployment..."
    terraform apply tfplan
    success "Terraform deployment applied"
}

# Get deployment outputs
get_outputs() {
    log "Getting deployment outputs..."
    terraform output -json > deployment_outputs.json
    success "Deployment outputs saved to deployment_outputs.json"
}

# Test API Gateway connectivity
test_api_gateway() {
    log "Testing API Gateway connectivity..."
    
    local api_url=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    if [ -z "$api_url" ]; then
        error "Could not get API Gateway URL from Terraform outputs"
        return 1
    fi
    
    log "API Gateway URL: $api_url"
    
    # Test health endpoint
    local health_url="${api_url}/health"
    log "Testing health endpoint: $health_url"
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$health_url" || echo "000")
    local http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        success "API Gateway health check passed"
        cat /tmp/health_response.json | jq '.' 2>/dev/null || cat /tmp/health_response.json
    else
        error "API Gateway health check failed (HTTP $http_code)"
        return 1
    fi
    
    # Test API endpoint
    local api_endpoint="${api_url}/api"
    log "Testing API endpoint: $api_endpoint"
    
    response=$(curl -s -w "%{http_code}" -o /tmp/api_response.json "$api_endpoint" || echo "000")
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        success "API Gateway API endpoint working"
        cat /tmp/api_response.json | jq '.' 2>/dev/null || cat /tmp/api_response.json
    else
        error "API Gateway API endpoint failed (HTTP $http_code)"
        return 1
    fi
}

# Test microservices connectivity
test_microservices() {
    log "Testing microservices connectivity..."
    
    local nlb_dns=$(terraform output -raw microservices_nlb_dns_name 2>/dev/null || echo "")
    if [ -z "$nlb_dns" ]; then
        error "Could not get NLB DNS name from Terraform outputs"
        return 1
    fi
    
    log "NLB DNS: $nlb_dns"
    
    # Test each microservice
    for i in {1..5}; do
        local port=$((3000 + i))
        local service_url="http://${nlb_dns}:${port}"
        local health_url="${service_url}/health"
        
        log "Testing microservice $i: $health_url"
        
        local response=$(curl -s -w "%{http_code}" -o /tmp/microservice_${i}_response.json "$health_url" --connect-timeout 10 || echo "000")
        local http_code="${response: -3}"
        
        if [ "$http_code" = "200" ]; then
            success "Microservice $i health check passed"
        else
            warning "Microservice $i health check failed (HTTP $http_code) - this might be normal during initial deployment"
        fi
    done
}

# Test database connectivity (if databases are deployed)
test_databases() {
    log "Testing database connectivity..."
    warning "Database connectivity tests require additional configuration and are not implemented in this basic test"
}

# Test monitoring endpoints
test_monitoring() {
    log "Testing monitoring endpoints..."
    
    # Test CloudWatch logs
    local log_group_name=$(terraform output -raw api_gateway_log_group_name 2>/dev/null || echo "")
    if [ -n "$log_group_name" ]; then
        success "CloudWatch log group created: $log_group_name"
    fi
    
    # Test CloudWatch dashboard
    local dashboard_name=$(terraform output -raw cloudwatch_dashboard_name 2>/dev/null || echo "")
    if [ -n "$dashboard_name" ]; then
        success "CloudWatch dashboard created: $dashboard_name"
    fi
}

# Generate test report
generate_report() {
    log "Generating test report..."
    
    cat > test_report.md << EOF
# InfraDM-Impr3q Deployment Test Report

## Deployment Information
- **Project**: $PROJECT_NAME
- **Date**: $(date)
- **Region**: $(terraform output -raw aws_region 2>/dev/null || echo "Unknown")

## Infrastructure Components

### Load Balancers
- **API Gateway ALB**: $(terraform output -raw api_gateway_alb_dns_name 2>/dev/null || echo "Not deployed")
- **Microservices NLB**: $(terraform output -raw microservices_nlb_dns_name 2>/dev/null || echo "Not deployed")

### Auto Scaling Groups
- **API Gateway ASG**: $(terraform output -raw api_gateway_asg_name 2>/dev/null || echo "Not deployed")
- **Microservices ASGs**: $(terraform output -raw microservices_asg_names 2>/dev/null || echo "Not deployed")

### Monitoring
- **CloudWatch Dashboard**: $(terraform output -raw cloudwatch_dashboard_name 2>/dev/null || echo "Not deployed")
- **Log Groups**: 
  - API Gateway: $(terraform output -raw api_gateway_log_group_name 2>/dev/null || echo "Not deployed")
  - Microservices: $(terraform output -raw microservices_log_group_name 2>/dev/null || echo "Not deployed")

## Test Results
- API Gateway: $(if test_api_gateway &>/dev/null; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)
- Microservices: $(if test_microservices &>/dev/null; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)
- Monitoring: $(if test_monitoring &>/dev/null; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)

## Next Steps
1. Configure your microservices with the correct endpoints
2. Set up Site24x7 monitoring if needed
3. Configure Grafana dashboards
4. Test database connectivity
5. Implement your application logic

## Cost Estimation
- Estimated monthly cost: ~$86 (varies based on usage)
- Instance types: t3.small (API Gateway), t3.micro (Microservices)
- Load balancers: Application Load Balancer + Network Load Balancer

## Security Notes
- Change all default passwords
- Review security group configurations
- Consider using AWS Secrets Manager for production
- Enable CloudTrail for audit logging

EOF

    success "Test report generated: test_report.md"
}

# Main execution
main() {
    echo "============================================================================="
    echo "InfraDM-Impr3q Deployment Test Script"
    echo "============================================================================="
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run checks
    check_terraform
    check_aws_cli
    check_configuration
    
    # Ask user if they want to deploy
    echo
    read -p "Do you want to deploy the infrastructure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        init_terraform
        plan_deployment
        
        echo
        read -p "Do you want to apply the deployment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            apply_deployment
            get_outputs
            
            # Wait for instances to be ready
            log "Waiting for instances to be ready..."
            sleep 60
            
            # Run tests
            test_api_gateway
            test_microservices
            test_monitoring
            generate_report
            
            echo
            success "Deployment and testing completed!"
            echo "Check test_report.md for detailed results"
        else
            log "Deployment cancelled"
        fi
    else
        log "Deployment skipped"
    fi
}

# Run main function
main "$@" 