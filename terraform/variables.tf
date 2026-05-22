variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where resources will be created"
}

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table shared with the URL shortener service"
}

variable "table_stats_name" {
  type        = string
  description = "Nombre de la tabla de DynamoDB asignada para las estadisticas de clicks"
}

variable "api_gateway_id" {
  type        = string
  description = "ID del API Gateway HTTP creado por el Módulo 1"
}

variable "api_gateway_execution_arn" {
  type        = string
  description = "Execution ARN del API Gateway del Módulo 1 (para el permiso de Lambda)"
}
