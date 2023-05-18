locals {
  app_name_and_env = "${var.app_name}-${local.app_env}"
  app_env          = data.terraform_remote_state.common.outputs.app_env
  app_environment  = data.terraform_remote_state.common.outputs.app_environment
  mysql_database   = "session"
  mysql_user       = "root"
  name_tag_suffix  = "${var.app_name}-${var.customer}-${local.app_environment}"
}

/*
 * Create ECR repo
 */
module "ecr" {
  source                = "github.com/silinternational/terraform-modules//aws/ecr?ref=8.0.1"
  repo_name             = local.app_name_and_env
  ecsInstanceRole_arn   = data.terraform_remote_state.common.outputs.ecsInstanceRole_arn
  ecsServiceRole_arn    = data.terraform_remote_state.common.outputs.ecsServiceRole_arn
  cd_user_arn           = data.terraform_remote_state.common.outputs.codeship_arn
  image_retention_count = 20
  image_retention_tags  = ["latest", "develop"]
}

/*
 * Create Cloudwatch log group
 */
resource "aws_cloudwatch_log_group" "logs" {
  name              = local.app_name_and_env
  retention_in_days = 30

  tags = {
    name = "cloudwatch_log_group-${local.name_tag_suffix}"
  }
}

/*
 * Create target group for ALB
 */
resource "aws_alb_target_group" "tg" {
  name                 = substr("tg-${local.app_name_and_env}", 0, 32)
  port                 = "80"
  protocol             = "HTTP"
  vpc_id               = data.terraform_remote_state.common.outputs.vpc_id
  deregistration_delay = "30"

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path    = "/"
    matcher = "302"
  }

  tags = {
    name = "alb_target_group-${local.name_tag_suffix}"
  }
}

/*
 * Create listener rule for hostname routing to new target group
 */
resource "aws_alb_listener_rule" "tg" {
  listener_arn = data.terraform_remote_state.common.outputs.alb_https_listener_arn
  priority     = "217"

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["${var.subdomain}.${var.cloudflare_domain}"]
    }
  }

  tags = {
    name = "alb_listener_rule-${local.name_tag_suffix}"
  }
}

/*
 *  Create cloudwatch dashboard for service
 */
module "ecs-service-cloudwatch-dashboard" {
  count = var.create_dashboard ? 1 : 0

  source  = "silinternational/ecs-service-cloudwatch-dashboard/aws"
  version = "~> 2.0.0"

  cluster_name   = data.terraform_remote_state.common.outputs.ecs_cluster_name
  dashboard_name = local.app_name_and_env
  service_names  = [var.app_name]
  aws_region     = var.aws_region
}

/*
 * Create Elasticache subnet group
 */
resource "aws_elasticache_subnet_group" "memcache_subnet_group" {
  count = var.session_store_type == "memcache" ? 1 : 0

  name       = local.app_name_and_env
  subnet_ids = data.terraform_remote_state.common.outputs.private_subnet_ids

  tags = {
    name = "elasticache_subnet_group-${local.name_tag_suffix}"
  }
}

/*
 * Create Elasticache cluster
 */
resource "aws_elasticache_cluster" "memcache" {
  count = var.session_store_type == "memcache" ? 1 : 0

  cluster_id           = local.app_name_and_env
  engine               = "memcached"
  node_type            = var.memcache_node_type
  port                 = var.memcache_port
  num_cache_nodes      = var.memcache_num_cache_nodes
  parameter_group_name = var.memcache_parameter_group_name
  security_group_ids   = [data.terraform_remote_state.common.outputs.vpc_default_sg_id]
  subnet_group_name    = one(aws_elasticache_subnet_group.memcache_subnet_group[*].name)
  az_mode              = var.memcache_az_mode


  tags = {
    name = "elasticache_cluster-${local.name_tag_suffix}"
  }
}

/*
 * Create RDS root password
 */
resource "random_password" "db_root" {
  count = var.session_store_type == "sql" ? 1 : 0

  length = 16
}

/*
 * Create RDS database for session store, if session_store_type is "sql"
 */
module "rds" {
  count = 1
  #  count = var.session_store_type == "sql" ? 1 : 0

  source = "github.com/silinternational/terraform-modules//aws/rds/mariadb?ref=8.0.1"

  app_name          = var.app_name
  app_env           = local.app_env
  db_name           = local.mysql_database
  db_root_user      = local.mysql_user
  db_root_pass      = one(random_password.db_root[*].result)
  subnet_group_name = data.terraform_remote_state.common.outputs.db_subnet_group_name
  security_groups   = [data.terraform_remote_state.common.outputs.vpc_default_sg_id]

  allocated_storage = 20 // 20 gibibyte
  instance_class    = "db.t3.micro"
  multi_az          = true
  tags = {
    managed_by        = "terraform"
    workspace         = terraform.workspace
    itse_app_customer = var.customer
    itse_app_env      = local.app_environment
    itse_app_name     = "idp-hub"
  }
}

/*
 * Create required passwords
 */
resource "random_id" "ssp_admin_pass" {
  byte_length = 32
}

resource "random_id" "ssp_secret_salt" {
  byte_length = 32
}

locals {
  memcache_host1 = one(aws_elasticache_cluster.memcache[*].cache_nodes[0].address)
  memcache_host2 = one(aws_elasticache_cluster.memcache[*].cache_nodes[1].address)
  mysql_host     = one(module.rds[*].address)
  mysql_password = one(random_password.db_root[*].result)
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
    cloudwatch_log_group_name = aws_cloudwatch_log_group.logs.name
    cloudflare_domain         = var.cloudflare_domain
    cpu                       = var.cpu
    docker_image              = module.ecr.repo_url
    docker_tag                = var.docker_tag
    dynamo_access_key_id      = aws_iam_access_key.user_login_logger.id
    dynamo_secret_access_key  = aws_iam_access_key.user_login_logger.secret
    help_center_url           = var.help_center_url
    idp_display_name          = var.idp_display_name
    idp_name                  = var.idp_name
    memcache_host1            = local.memcache_host1 == null ? "" : local.memcache_host1
    memcache_host2            = local.memcache_host2 == null ? "" : local.memcache_host2
    memory                    = var.memory
    mysql_host                = local.mysql_host == null ? "" : local.mysql_host
    mysql_database            = local.mysql_database
    mysql_user                = local.mysql_user
    mysql_password            = local.mysql_password == null ? "" : local.mysql_password
    secret_salt               = random_id.ssp_secret_salt.hex
    session_store_type        = var.session_store_type
    show_saml_errors          = var.show_saml_errors
    subdomain                 = var.subdomain
  }
}

/*
 * Create new ecs service
 */
module "ecs" {
  source             = "github.com/silinternational/terraform-modules//aws/ecs/service-only?ref=8.0.1"
  cluster_id         = data.terraform_remote_state.common.outputs.ecs_cluster_id
  service_name       = var.app_name
  service_env        = local.app_env
  container_def_json = data.template_file.task_def_hub.rendered
  desired_count      = var.desired_count
  tg_arn             = aws_alb_target_group.tg.arn
  lb_container_name  = "hub"
  lb_container_port  = "80"
  ecsServiceRole_arn = data.terraform_remote_state.common.outputs.ecsServiceRole_arn
}

/*
 * Create user for dynamo permissions
 */
resource "aws_iam_user" "user_login_logger" {
  name = "idp_hub_user_login_logger-${local.app_env}"
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
  name = "dynamodb_user_login_logger_policy-${local.app_env}"
  user = aws_iam_user.user_login_logger.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["dynamodb:PutItem"],
        "Resource" : "arn:aws:dynamodb:*:*:table/sildisco_*_user-log"
      }
    ]
  })
}

/*
 * Create Cloudflare DNS record
 */
resource "cloudflare_record" "dns" {
  count   = var.create_dns_entry
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.subdomain
  value   = data.terraform_remote_state.common.outputs.alb_dns_name
  type    = "CNAME"
  proxied = true
}

data "cloudflare_zones" "domain" {
  filter {
    name        = var.cloudflare_domain
    lookup_type = "exact"
    status      = "active"
  }
}
