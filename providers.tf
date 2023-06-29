provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key

  default_tags {
    tags = {
      managed_by        = "terraform"
      workspace         = terraform.workspace
      itse_app_customer = var.customer
      itse_app_env      = local.app_environment
      itse_app_name     = "idp-hub"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
