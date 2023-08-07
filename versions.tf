terraform {
  required_version = ">= 0.15.5"
  required_providers {
    aws = {
      version = ">=3.72.0, < 4.0.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    region         = "eu-west-2"
    bucket         = "ramg-demo"
    key            = "ramg.tfstate"
    dynamodb_table = "tessian"
    encrypt        = "true"
  }
}