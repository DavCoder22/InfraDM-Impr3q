module "user_service" {
  source = "./modules/microservice"
  
  rest_api_id             = aws_api_gateway_rest_api.main.id
  parent_resource_id       = aws_api_gateway_rest_api.main.root_resource_id
  service_path            = "users"
  http_method             = "ANY"
  authorization           = "NONE"
  lambda_invoke_arn       = "arn:aws:lambda:us-east-1:123456789012:function:user-service"
  lambda_function_name    = "user-service"
  api_gateway_execution_arn = aws_api_gateway_rest_api.main.execution_arn
}

# Ejemplo de un segundo microservicio
module "product_service" {
  source = "./modules/microservice"
  
  rest_api_id             = aws_api_gateway_rest_api.main.id
  parent_resource_id       = aws_api_gateway_rest_api.main.root_resource_id
  service_path            = "products"
  http_method             = "ANY"
  authorization           = "COGNITO_USER_POOLS"
  lambda_invoke_arn       = "arn:aws:lambda:us-east-1:123456789012:function:product-service"
  lambda_function_name    = "product-service"
  api_gateway_execution_arn = aws_api_gateway_rest_api.main.execution_arn
}
