variable "rest_api_id" {
  description = "ID of the parent REST API"
  type        = string
}

variable "parent_resource_id" {
  description = "ID of the parent resource"
  type        = string
}

variable "service_path" {
  description = "Path part for the microservice"
  type        = string
}

variable "http_method" {
  description = "HTTP method for the microservice endpoint"
  type        = string
  default     = "ANY"
}

variable "authorization" {
  description = "Type of authorization for the endpoint"
  type        = string
  default     = "NONE"
}

variable "lambda_invoke_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}
