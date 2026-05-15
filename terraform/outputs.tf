output "api_endpoint" {
  description = "Base URL for the redirection API"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "redirection_url" {
  description = "Full redirection endpoint pattern"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/{shortCode}"
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.redirection_lambda.function_name
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.api.id
}