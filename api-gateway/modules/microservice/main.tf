resource "aws_api_gateway_resource" "service" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_resource_id
  path_part   = var.service_path
}

resource "aws_api_gateway_method" "service_method" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.service.id
  http_method   = var.http_method
  authorization = var.authorization
  
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "service_integration" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.service.id
  http_method = aws_api_gateway_method.service_method.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
  
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Permisos para que API Gateway pueda invocar la Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${var.api_gateway_execution_arn}/*/*/*"
}
