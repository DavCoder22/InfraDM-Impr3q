# Minimal AWS Configuration for AWS Educate
provider "aws" {
  region = "us-east-1"
}

# Get current AWS account info
data "aws_caller_identity" "current" {}

# Output the account information
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Try to list available S3 buckets (usually one of the most permissive services)
data "aws_s3_bucket" "test" {
  bucket = "non-existent-bucket-123456"
}

# Output the S3 bucket ARN (will fail if no permissions)
output "s3_bucket_arn" {
  value = data.aws_s3_bucket.test.arn
}
