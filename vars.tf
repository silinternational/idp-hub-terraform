
/*
 * General config
 */

variable "app_name" {
  description = "A name to be used, combined with \"app_env\", for naming resources. Should be unique in the AWS account."
  type        = string
  default     = "idp-hub"
}

variable "app_env" {
  description = "The abbreviated version of the environment used for naming resources, typically either stg or prod"
  type        = string
  default     = "dev"
}

variable "app_environment" {
  description = "the full, unabbreviated environment used for AWS tags, typically either staging or production"
  type        = string
  default     = "development"
}

variable "customer" {
  description = "Customer name, used in AWS tags"
  type        = string
  default     = "shared"
}


/*
 * AWS configuration
 */

variable "aws_access_key_id" {
  description = "The AWS IAM access key ID for a user with permission to manage all of the resources defined in this module. Can be specified in environment variable AWS_ACCESS_KEY_ID."
  type        = string
  default     = null
}

variable "aws_secret_access_key" {
  description = "The AWS IAM secret access key for a user with permission to manage all of the resources defined in this module. Can be specified in environment variable AWS_SECRET_ACCESS_KEY."
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region in which to create all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_region_secondary" {
  description = "AWS region in which to create replica resources. If omitted, no replicas are created and this hub is configured to be the secondary."
  type        = string
  default     = ""
}

variable "cd_user_arn" {
  description = "ARN of the Continuous Deployment (CD) user created by the primary hub in a multiregion configuration. Ignored in a single-region configuration."
  type        = string
  default     = ""
}

variable "docker_tag" {
  description = "Docker tag to use in the task definition. Must match the tag name defined in the instance repo's `push_latest` step."
  type        = string
  default     = "latest"
}

variable "create_dashboard" {
  description = "Set to true to create a CloudWatch dashboard"
  type        = bool
  default     = true
}


/*
 * Task definition configuration
 */

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

variable "cpu" {
  description = "The hard limit of CPU units to present for the task, expressed as an integer using CPU units, e.g. 512 = 0.5 vCPU"
  type        = string
  default     = "128"
}

variable "idp_display_name" {
  description = "The name of the hub as presented to the end user."
  type        = string
  default     = "IdP dev hub"
}

variable "idp_name" {
  description = "Required by ssp-base, but not actually used."
  type        = string
  default     = "hub"
}

variable "help_center_url" {
  description = "The URL for the \"Help\" link at the top of the IDP selection page"
  type        = string
  default     = ""
}

variable "memory" {
  description = "The hard limit of memory (in MiB) to present to the task, expressed as an integer"
  type        = string
  default     = "128"
}

variable "show_saml_errors" {
  description = "Used for SimpleSAMLphp `showerrors` config option. When enabled, all error messages and stack traces will be output to the browser."
  type        = string
  default     = "false"
}


/*
 * DNS configuration
 */

variable "cloudflare_domain" {
  description = "The domain name on which to host the app. Combined with \"subdomain\" to create an ALB listener rule. Also used for the optional DNS record."
  type        = string
}

variable "cloudflare_token" {
  description = "The Cloudflare API token with permissions on the zone identified by `cloudflare_domain`."
  type        = string
  default     = null
}

variable "create_dns_record" {
  description = "Set to false to skip creation of a Cloudflare DNS record"
  type        = string
  default     = true
}

variable "subdomain" {
  description = "The subdomain on which to host the app. Combined with \"cloudflare_domain\" to create an ALB listener rule. Also used for the optional DNS record."
  type        = string
  default     = "hub"
}

/*
 * ECS and ASG configuration
 */

variable "asg_min_size" {
  description = "minimum number of EC2 instances in the autoscaling group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "maximum number of EC2 instances in the autoscaling group"
  type        = number
  default     = 2
}

variable "alarm_actions_enabled" {
  description = "True/false enable auto-scaling events and actions"
  type        = bool
  default     = false
}

variable "desired_count" {
  description = "Number of tasks to place and keep running."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#AvailableInstanceTypes"
  default     = "t2.micro"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of SSH key pair to use as default (ec2-user) user key. Set in the launch template"
  type        = string
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
