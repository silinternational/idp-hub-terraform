variable "admin_email" {
}

variable "admin_name" {
}

variable "analytics_id" {
}

variable "app_name" {
  default = "idp-hub"
}

variable "app_env" {
  type        = string
  description = "the abbreviated version of the environment used for naming resources, typically either stg or prod"
}

variable "app_environment" {
  type        = string
  description = "the full, unabbreviated environment used for AWS tags, typically either staging or production"
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
  description = "type of storage to use for sessions, can be \"memcache\" or \"sql\""
  default     = "sql"
}

variable "show_saml_errors" {
  default = "false"
}

variable "subdomain" {
}

variable "customer" {
  description = "Customer name, used in AWS tags"
  type        = string
}

variable "create_dashboard" {
  description = "Set to true to create a CloudWatch dashboard"
  type        = bool
  default     = true
}


/*
 * ECS and ASG configuration
 */

variable "asg_min_size" {
  default = "1"
}

variable "asg_max_size" {
  default = "5"
}

variable "alarm_actions_enabled" {
  default     = false
  description = "True/false enable auto-scaling events and actions"
}

variable "ssh_key_name" {
  default = ""
}

/*
 * VPC configuration
 */

variable "aws_zones" {
  type    = list(string)
  default = ["us-east-1c", "us-east-1d", "us-east-1e"]
}

/*
 * ALB configuration
 */

variable "default_cert_domain_name" {
  type        = string
  description = "Default/primary certificate domain name"
}
