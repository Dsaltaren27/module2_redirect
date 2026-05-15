# --- IAM ROLE ---
resource "aws_iam_role" "lambda_role" {
  name = "role_redirection_service"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

# --- PERMISOS (CloudWatch + DynamoDB) ---
resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamo_read" {
  name = "policy_redirection_dynamo_read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = ["dynamodb:GetItem"], Effect = "Allow", Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}" }]
  })
}
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "dynamo_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamo_read.arn
}



# --- LAMBDA FUNCTION ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "redirection_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "url-shortener-redirection"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handlers/redirect.handler" # Asegúrate de que coincida con tu estructura
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # VITAL: Aquí le pasas el nombre de la tabla a tu código JS
  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}



# --- API GATEWAY HTTP ---
resource "aws_apigatewayv2_api" "api" {
  name          = "api-redirecion-module2"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "int" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  # Asegúrate de que el nombre coincida con tu recurso aws_lambda_function
  integration_uri  = aws_lambda_function.redirection_lambda.invoke_arn 
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  # CAMBIO CLAVE: Método GET y parámetro dinámico entre llaves
  route_key = "GET /{shortCode}" 
  target    = "integrations/${aws_apigatewayv2_integration.int.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  # Asegúrate de que el nombre coincida con tu recurso aws_lambda_function
  function_name = aws_lambda_function.redirection_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}