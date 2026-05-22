terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend en S3 para que el remote state funcione en CI/CD y entre módulos
  # Asegúrate de crear este bucket manualmente antes del primer `terraform init`
  backend "s3" {
    bucket = "url-shortener-frontend-parcial3"
    key    = "module2_redirection/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
