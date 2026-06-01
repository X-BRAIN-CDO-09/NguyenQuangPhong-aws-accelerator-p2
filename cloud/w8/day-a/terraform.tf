terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # short form of "registry.terraform.io/hashicorp/aws"
      version = "~> 5.92"       # version of AWS provider to use
    }
  }

  required_version = ">= 1.2" # version of Terraform to use
}
