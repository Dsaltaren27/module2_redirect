variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where resources will be created"
}

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table shared with the URL shortener service"
  default     = "UrlsTable"
}

variable "table_stats_name" {
  type        = string
  description = "Nombre de la tabla de DynamoDB asignada para las estadisticas de clicks"
  default     = "LinkClicksTable" # <-- Configurado exactamente con el nombre de tu entorno
}