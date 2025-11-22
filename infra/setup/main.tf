terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }

  backend "s3" {
    bucket         = "devops-sw-pipelines-assignment-3-tf-state"
    key            = "terraform-state-setup"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "devops-sw-pipelines-assignment-3-tf-state"
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      contact     = var.contact
      ManageBy    = "Terraform/setup"
    }
  }
}
