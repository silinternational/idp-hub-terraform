
terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
    cloudflare = {
      version = "~> 3.7"
      source  = "cloudflare/cloudflare"
    }
    random = {
      version = "~> 3.1"
      source  = "hashicorp/random"
    }
  }
}
