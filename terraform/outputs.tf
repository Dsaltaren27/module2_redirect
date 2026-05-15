output "api_endpoint" {
  description = "Base URL for the redirection API"
  value       = data.aws_apigatewayv2_api.module1_api.api_endpoint
}

output "redirection_url" {
  description = "Full redirection endpoint pattern"
  value       = "${data.aws_apigatewayv2_api.module1_api.api_endpoint}/{shortCode}"
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.redirection_lambda.function_name
}

output "api_id" {
  description = "API Gateway ID"
  value       = data.aws_apigatewayv2_api.module1_api.id
}