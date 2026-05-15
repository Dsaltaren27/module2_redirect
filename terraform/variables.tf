variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where resources will be created"
}

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table shared with the URL shortener service"
  # This variable MUST be provided or set via terraform.tfvars
}