variable "admin_email" {
  default = "info@insitehome.org"
}

variable "admin_name" {
  default = "Insite Admin"
}

variable "analytics_id" {
}

variable "app_name" {
  default = "idp-hub"
}

variable "aws_access_key" {
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_secret_key" {
}

variable "cloudflare_domain" {
}

variable "cloudflare_token" {
  description = "The Cloudflare API token with permissions on `cloudflare_domain`."
  default     = ""
}

variable "cpu" {
  default = "128"
}

variable "create_dns_entry" {
  description = "Set to 1 to create Cloudflare entry, 0 to not create entry"
  default     = 1
}

variable "desired_count" {
  default = 2
}

variable "docker_tag" {
  default = "latest"
}

variable "help_center_url" {
  description = "Appears at the top of the IDP selection page"
  type        = string
  default     = ""
}

variable "idp_display_name" {
}

variable "idp_name" {
}

variable "memcache_az_mode" {
  type    = string
  default = "cross-az"
}

variable "memcache_node_type" {
  default = "cache.t2.micro"
}

variable "memcache_num_cache_nodes" {
  type    = string
  default = 2
}

variable "memcache_parameter_group_name" {
  type    = string
  default = "default.memcached1.5"
}

variable "memcache_port" {
  type    = string
  default = "11211"
}

variable "memory" {
  default = "128"
}

variable "session_store_type" {
  default = "memcache"
}

variable "show_saml_errors" {
  default = "false"
}

variable "subdomain" {
}

variable "tf_remote_common" {
  description = "Path to the Common remote, in `org/workspace` syntax."
}
