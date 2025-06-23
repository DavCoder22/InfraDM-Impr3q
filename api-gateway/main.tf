provider "aws" {
  region = var.aws_region
}

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = var.api_gateway_description
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Recurso raíz
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# Método ANY para manejar todas las operaciones
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integración con Lambda (ajusta según necesites)
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Despliegue
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda]
  
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name
}

# Outputs
output "api_gateway_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
