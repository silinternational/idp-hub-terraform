
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
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.5, < 3.0.0"
    }
    random = {
      version = "~> 3.1"
      source  = "hashicorp/random"
    }
  }
}
