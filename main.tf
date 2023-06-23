locals {
  app_name_and_env = "${var.app_name}-${local.app_env}"
  app_env          = var.app_env
  app_environment  = var.app_environment
  ecr_repo_name    = local.app_name_and_env
  is_multiregion   = var.aws_region_secondary != ""
  is_primary       = local.is_multiregion && var.aws_region != var.aws_region_secondary
  mysql_database   = "session"
  mysql_user       = "root"
  name_tag_suffix  = "${var.app_name}-${var.customer}-${local.app_environment}"
}

module "app" {
  source = "github.com/silinternational/terraform-aws-ecs-app?ref=develop"

  app_env                  = local.app_env
  app_name                 = var.app_name
  domain_name              = var.cloudflare_domain
  container_def_json       = data.template_file.task_def_hub.rendered
  create_dns_record        = var.create_dns_record
  create_cd_user           = !local.is_multiregion || local.is_primary
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
data "template_file" "task_def_hub" {
  template = file("${path.module}/task-def-hub.json")

  vars = {
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
  }
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
  source                = "github.com/silinternational/terraform-modules//aws/ecr?ref=8.2.1"
  repo_name             = local.ecr_repo_name
  ecsInstanceRole_arn   = module.app.ecsInstanceRole_arn
  ecsServiceRole_arn    = module.app.ecsServiceRole_arn
  cd_user_arn           = module.app.cd_user_arn
  image_retention_count = 20
  image_retention_tags  = ["latest", "develop"]
}

resource "aws_ecr_replication_configuration" "this" {
  count      = local.is_primary ? 1 : 0
  depends_on = [module.ecr]

  replication_configuration {
    rule {
      destination {
        region      = var.aws_region_secondary
        registry_id = data.aws_caller_identity.this.account_id
      }
      repository_filter {
        filter      = local.ecr_repo_name
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

data "aws_caller_identity" "this" {}

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
