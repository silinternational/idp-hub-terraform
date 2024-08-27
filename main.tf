locals {
  app_name_and_env       = "${var.app_name}-${local.app_env}"
  app_env                = var.app_env
  app_environment        = var.app_environment
  ecr_repo_name          = local.app_name_and_env
  is_multiregion         = var.aws_region_secondary != ""
  is_multiregion_primary = local.is_multiregion && var.aws_region != var.aws_region_secondary
  create_cd_user         = !local.is_multiregion || local.is_multiregion_primary
  mysql_database         = "session"
  mysql_user             = "root"
  name_tag_suffix        = "${var.app_name}-${var.customer}-${local.app_environment}"
}

module "app" {
  source  = "silinternational/ecs-app/aws"
  version = "0.6.0"

  app_env                  = local.app_env
  app_name                 = var.app_name
  domain_name              = var.cloudflare_domain
  container_def_json       = local.task_def_hub
  create_dns_record        = false
  create_cd_user           = local.create_cd_user
  database_name            = local.mysql_database
  database_user            = local.mysql_user
  desired_count            = var.desired_count
  subdomain                = var.subdomain
  create_dashboard         = var.create_dashboard
  asg_min_size             = var.asg_min_size
  asg_max_size             = var.asg_max_size
  instance_type            = var.instance_type
  alarm_actions_enabled    = var.alarm_actions_enabled
  ssh_key_name             = var.ssh_key_name
  aws_zones                = var.aws_zones
  default_cert_domain_name = "*.${var.cloudflare_domain}"
  create_adminer           = true
  enable_adminer           = var.enable_adminer
  rds_ca_cert_identifier   = "rds-ca-rsa2048-g1"
  health_check = {
    matcher = "302,303"
    path    = "/"
  }
}


/*
 * Create intermediate DNS record using Cloudflare (e.g. hub-us-east-2.example.com)
 */
resource "cloudflare_record" "intermediate" {
  zone_id = data.cloudflare_zone.this.id
  name    = "${var.subdomain}-${var.aws_region}"
  value   = module.app.alb_dns_name
  type    = "CNAME"
  comment = "intermediate record - DO NOT change this"
  proxied = true
}

/*
 * Create public DNS record using Cloudflare (e.g. hub.example.com)
 */
resource "cloudflare_record" "public" {
  count = local.is_multiregion_primary || !local.is_multiregion ? 1 : 0

  zone_id = data.cloudflare_zone.this.id
  name    = var.subdomain
  value   = cloudflare_record.intermediate.hostname
  type    = "CNAME"
  comment = "public record - this can be changed for failover"
  proxied = true
}

data "cloudflare_zone" "this" {
  name = var.cloudflare_domain
}


/*
 * Create passwords required for SimpleSAMLphp
 */

resource "random_id" "ssp_admin_pass" {
  byte_length = 32
}

resource "random_id" "ssp_secret_salt" {
  byte_length = 32
}

/*
 * Create task definition template
 */
locals {
  task_def_hub = templatefile("${path.module}/task-def-hub.json", {
    admin_email               = var.admin_email
    admin_name                = var.admin_name
    admin_pass                = random_id.ssp_admin_pass.hex
    analytics_id              = var.analytics_id
    app_env                   = local.app_env
    app_name                  = var.app_name
    aws_region                = var.aws_region
    cloudwatch_log_group_name = module.app.cloudwatch_log_group_name
    cloudflare_domain         = var.cloudflare_domain
    cpu                       = var.cpu
    docker_image              = module.ecr.repo_url
    docker_tag                = var.docker_tag
    dynamo_access_key_id      = aws_iam_access_key.user_login_logger.id
    dynamo_secret_access_key  = aws_iam_access_key.user_login_logger.secret
    enable_debug              = var.enable_debug
    help_center_url           = var.help_center_url
    idp_display_name          = var.idp_display_name
    idp_name                  = var.idp_name
    memory                    = var.memory
    mysql_host                = module.app.database_host
    mysql_database            = local.mysql_database
    mysql_user                = local.mysql_user
    mysql_password            = module.app.database_password
    secret_salt               = random_id.ssp_secret_salt.hex
    session_store_type        = "sql"
    show_saml_errors          = var.show_saml_errors
    subdomain                 = var.subdomain
    theme_color_scheme        = var.theme_color_scheme
  })
}

/*
 * Create user for dynamo permissions
 */
resource "aws_iam_user" "user_login_logger" {
  name = "idp_hub_user_login_logger-${local.app_name_and_env}-${var.aws_region}"
}

/*
 * Create key for dynamo permissions
 */
resource "aws_iam_access_key" "user_login_logger" {
  user = aws_iam_user.user_login_logger.name
}

/*
 * Allow user_login_logger user to write to Dynamodb
 */
resource "aws_iam_user_policy" "dynamodb-logger-policy" {
  name = "dynamodb_user_login_logger_policy-${local.app_name_and_env}"
  user = aws_iam_user.user_login_logger.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["dynamodb:PutItem"],
        "Resource" : aws_dynamodb_table.logger.arn
      }
    ]
  })
}

/*
 * Create ECR repo
 */
module "ecr" {
  source                = "github.com/silinternational/terraform-modules//aws/ecr?ref=8.8.0"
  repo_name             = local.ecr_repo_name
  ecsInstanceRole_arn   = module.app.ecsInstanceRole_arn
  ecsServiceRole_arn    = module.app.ecsServiceRole_arn
  cd_user_arn           = local.create_cd_user ? module.app.cd_user_arn : var.cd_user_arn
  image_retention_count = 20
  image_retention_tags  = ["latest", "develop"]
}


/*
 * DynamoDB table for user login activity logging
 */

resource "aws_dynamodb_table" "logger" {
  name         = "${local.app_name_and_env}-user-log"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "ID"
    type = "S"
  }
  hash_key = "ID"
  ttl {
    enabled        = true
    attribute_name = "ExpiresAt"
  }
}


/*
 * AWS backup
 */
module "aws_backup" {
  count = var.enable_aws_backup ? 1 : 0

  source   = "github.com/silinternational/terraform-modules//aws/backup/rds?ref=8.8.0"
  app_name = var.app_name
  app_env  = var.app_env
  source_arns = [
    data.aws_db_instance.this.db_instance_arn,
    aws_dynamodb_table.logger.arn
  ]
  backup_cron_schedule = var.aws_backup_cron_schedule
  notification_events  = var.aws_backup_notification_events
}

data "aws_db_instance" "this" {
  db_instance_identifier = "idp-${var.idp_name}-${var.app_env}"
}
