variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_gateway_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "API Gateway for microservices"
}

variable "stage_name" {
  description = "Name of the deployment stage (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "lambda_invoke_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
