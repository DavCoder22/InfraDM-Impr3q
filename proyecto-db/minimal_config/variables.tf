# Configuración básica de variables
variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno (Producción, Desarrollo, Pruebas)"
  type        = string
  default     = "Producción"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "InfraDM"
}
