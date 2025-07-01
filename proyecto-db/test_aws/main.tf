# Minimal AWS Test Configuration
provider "aws" {
  region = "us-east-1"
}

# Get current AWS account info
data "aws_caller_identity" "current" {}

# Output the account information
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "user_id" {
  value = data.aws_caller_identity.current.user_id
}
