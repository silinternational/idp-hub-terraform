
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
  description = "AWS region in which to create ECR replicas. Must be specified in both the primary and secondary hub workspaces. Leave empty for a single-region setup."
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

variable "require_secure_transport" {
  description = "Set to true to require SSL for database connection."
  type        = bool
  default     = false
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

variable "enable_debug" {
  description = "Enables debug for SimpleSAMLphp 'saml' and 'validatexml' modes. CAUTION: may log decrypted SAML messages."
  type        = string
  default     = "false"
}

variable "help_center_url" {
  description = "The URL for the \"Help\" link at the top of the IDP selection page"
  type        = string
  default     = ""
}

variable "logging_level" {
  description = "Log level for log filter, may be one of: ERR, WARNING, NOTICE, INFO, DEBUG"
  type        = string
  default     = "NOTICE"
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

variable "theme_color_scheme" {
  description = "Set the color scheme for the material theme. Use one of: indigo-purple, blue_grey-teal, red-teal, orange-light_blue, brown-orange, teal-blue"
  type        = string
  default     = "indigo-purple"
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


/*
 * Optional features
 */

variable "create_dashboard" {
  description = "Set to true to create a CloudWatch dashboard for monitoring ECS memory and CPU utilization"
  type        = bool
  default     = true
}

variable "enable_adminer" {
  description = "Control the creation of a DNS record for Adminer and the desired_count for the Adminer ECS service"
  type        = bool
  default     = false
}


/*
 * AWS Backup
 */

variable "enable_aws_backup" {
  description = "enable backup using AWS Backup service"
  type        = bool
  default     = true
}

variable "aws_backup_cron_schedule" {
  description = "cron-type schedule for AWS Backup"
  type        = string
  default     = "5 14 * * ? *" # Every day at 3:05 UTC
}

variable "aws_backup_notification_events" {
  description = "The names of the backup events that should trigger an email notification"
  type        = list(string)
  default     = ["BACKUP_JOB_FAILED"]
}

variable "backup_sns_email" {
  description = "Optional: email address to receive backup event notifications"
  type        = string
  default     = ""
}

variable "delete_recovery_point_after_days" {
  description = "Number of days after which AWS Backup recovery points are deleted"
  type        = number
  default     = 30
}
