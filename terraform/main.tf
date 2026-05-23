# --- DATA SOURCES GLOBALES ---
data "aws_caller_identity" "current" {}

# --- IAM ROLE ---
resource "aws_iam_role" "lambda_role" {
  name = "role_redirection_service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# --- PERMISOS (CloudWatch + DynamoDB) ---
resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamo_read_write" {
  name        = "policy_redirection_dynamo_read_write"
  description = "Permite a la Lambda del Modulo 2 leer de UrlsTable y escribir en StatsTable"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadFromUrlsTable"
        Action   = ["dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"
      },
      {
        Sid      = "AllowWriteToStatsTable"
        Action   = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_stats_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamo_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamo_read_write.arn
}

# --- EMPAQUETADO DE LA LAMBDA ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambda"
  output_path = "${path.module}/lambda.zip"
}

# --- LAMBDA FUNCTION ---
resource "aws_lambda_function" "redirection_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "url-shortener-redirection"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handlers/redirect.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME       = var.table_name
      TABLE_STATS_NAME = var.table_stats_name
    }
  }
}

# --- INTEGRACIÓN CON API GATEWAY DEL MÓDULO 1 ---

resource "aws_apigatewayv2_integration" "int" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.redirection_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = var.api_gateway_id
  route_key = "GET /{shortCode}"
  target    = "integrations/${aws_apigatewayv2_integration.int.id}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayV2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirection_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
