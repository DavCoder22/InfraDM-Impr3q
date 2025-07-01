# Configuración mínima para AWS Educate
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "Production"
      Project     = "InfraDM"
      ManagedBy   = "Terraform"
    }
  }
}

# Obtener información de la cuenta actual
data "aws_caller_identity" "current" {}

# Outputs para verificar la configuración
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
