
terraform {
  required_version = ">= 1.1"
  required_providers {
    aws = {
      version = ">= 4.0.0, < 6.0.0"
      source  = "hashicorp/aws"
    }
    cloudflare = {
      version = ">= 3.7.0, < 5.0.0"
      source  = "cloudflare/cloudflare"
    }
    random = {
      version = "~> 3.1"
      source  = "hashicorp/random"
    }
  }
}
