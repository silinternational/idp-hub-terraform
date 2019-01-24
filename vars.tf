variable "admin_email" {
  default = "info@insitehome.org"
}

variable "admin_name" {
  default = "Insite Admin"
}

variable "analytics_id" {}

variable "app_name" {
  default = "idp-hub"
}

variable "aws_access_key" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_secret_key" {}

variable "cloudflare_domain" {}
variable "cloudflare_email" {}
variable "cloudflare_token" {}

variable "cpu" {
  default = "128"
}

variable "desired_count" {
  default = 2
}

variable "docker_tag" {
  default = "latest"
}

variable "idp_display_name" {}
variable "idp_name" {}
variable "logentries_account_key" {}

variable "memory" {
  default = "128"
}

variable "session_store_type" {
  default = "memcache"
}

variable "show_saml_errors" {
  default = "false"
}

variable "subdomain" {}
variable "tf_remote_common" {}
