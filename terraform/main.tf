# --- DATA SOURCES GLOBALES ---
data "aws_caller_identity" "current" {}

# --- IAM ROLE ---
resource "aws_iam_role" "lambda_role" {
  name = "role_redirection_service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

# --- PERMISOS (CloudWatch + Consulta de DynamoDB) ---
resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamo_read" {
  name        = "policy_redirection_dynamo_read"
  description = "Permite a la Lambda del Modulo 2 leer items de la tabla compartida"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"
      }
    ]
  })
}

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
  handler          = "handlers/redirect.handler" 
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}

# --- API GATEWAY HTTP SHARED WITH MODULE 1 ---
data "terraform_remote_state" "module1" {
  backend = "local"
  config = {
    path = "../../module1_shorten/terraform/terraform.tfstate"
  }
}

data "aws_apigatewayv2_api" "module1_api" {
  api_id = data.terraform_remote_state.module1.outputs.api_id
}

resource "aws_apigatewayv2_integration" "int" {
  api_id           = data.aws_apigatewayv2_api.module1_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.redirection_lambda.invoke_arn 
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = data.aws_apigatewayv2_api.module1_api.id
  route_key = "GET /{shortCode}"
  target    = "integrations/${aws_apigatewayv2_integration.int.id}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirection_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${data.aws_apigatewayv2_api.module1_api.execution_arn}/*/*"
}