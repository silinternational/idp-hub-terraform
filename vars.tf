variable "admin_email" {
  description = "SAML technical contact email. This information will be available in the generated metadata."
  type        = string
}

variable "admin_name" {
  description = "SAML technical contact name. This information will be available in the generated metadata."
  type        = string
}

variable "analytics_id" {
  description = "Google Analytics measurement ID"
  type        = string
}

variable "app_name" {
  description = "A name to be used, combined with \"app_env\", for naming resources. Should be unique in the AWS account."
  default     = "idp-hub"
}

variable "app_env" {
  description = "The abbreviated version of the environment used for naming resources, typically either stg or prod"
  type        = string
}

variable "app_environment" {
  description = "the full, unabbreviated environment used for AWS tags, typically either staging or production"
  type        = string
}

variable "deploy_user_arn" {
  description = "The ARN of a deployment service user, to be granted permissions to push and pull on the ECR repo"
  type        = string
}

variable "aws_access_key_id" {
  description = ""
}

variable "aws_region" {
  description = "AWS region in which to create all resources"
  default     = "us-east-1"
}

variable "aws_region_secondary" {
  description = "AWS region in which to create replica resources. If omitted, no replicas are created."
  default     = ""
}

variable "aws_secret_access_key" {
}

variable "cloudflare_domain" {
  description = "The domain name on which to host the app. Combined with \"subdomain\" to create an ALB listener rule. Also used for the optional DNS record."
}

variable "cloudflare_token" {
  description = "The Cloudflare API token with permissions on `cloudflare_domain`."
}

variable "cpu" {
  description = "The hard limit of CPU units to present for the task, expressed as an integer using CPU units, e.g. 512 = 0.5 vCPU"
  default     = "128"
}

variable "create_dns_record" {
  description = "Set to false to skip creation of a Cloudflare record"
  default     = true
}

variable "desired_count" {
  description = "Number of tasks to place and keep running."
  default     = 2
}

variable "docker_tag" {
  description = "Docker tag to use in the task definition. Must match the tag name defined in the instance repo's `push_latest` step."
  default     = "latest"
}

variable "help_center_url" {
  description = "The URL for the \"Help\" link at the top of the IDP selection page"
  type        = string
  default     = ""
}

variable "idp_display_name" {
  description = ""
}

variable "idp_name" {
  description = ""
}

variable "memory" {
  description = "The hard limit of memory (in MiB) to present to the task, expressed as an integer"
  default     = "128"
}

variable "show_saml_errors" {
  description = "Used for SimpleSAMLphp `showerrors` config option. When enabled, all error messages and stack traces will be output to the browser."
  default     = "false"
}

variable "subdomain" {
  description = "The subdomain on which to host the app. Combined with \"domain_name\" to create an ALB listener rule. Also used for the optional DNS record."
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
  description = "minimum number of EC2 instances in the autoscaling group"
  default     = 2
}

variable "asg_max_size" {
  description = "maximum number of EC2 instances in the autoscaling group"
  default     = 2
}

variable "alarm_actions_enabled" {
  description = "True/false enable auto-scaling events and actions"
  default     = false
}

variable "ssh_key_name" {
  description = "Name of SSH key pair to use as default (ec2-user) user key. Set in the launch template"
  default     = ""
}

/*
 * VPC configuration
 */

variable "aws_zones" {
  description = "The VPC availability zone list"
  type        = list(string)
  default     = ["us-east-1c", "us-east-1d", "us-east-1e"]
}
