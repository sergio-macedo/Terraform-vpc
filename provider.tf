terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.59.0"
    }
  }
}
provider "aws" {
  region  = "eu-central-1"
  profile = "sso-de-cloudification"
}