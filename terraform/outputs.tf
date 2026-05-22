output "lambda_function_name" {
  description = "Nombre de la Lambda de redirección"
  value       = aws_lambda_function.redirection_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN de la Lambda de redirección"
  value       = aws_lambda_function.redirection_lambda.arn
}

output "redirection_endpoint" {
  description = "Endpoint de redirección (usar con /{shortCode})"
  value       = "Usa el API Gateway del Módulo 1 con la ruta GET /{shortCode}"
}
