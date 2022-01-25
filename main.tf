/*
 * Create ECR repo
 */
module "ecr" {
  source              = "github.com/silinternational/terraform-modules//aws/ecr?ref=3.5.0"
  repo_name           = "${var.app_name}-${data.terraform_remote_state.common.outputs.app_env}"
  ecsInstanceRole_arn = data.terraform_remote_state.common.outputs.ecsInstanceRole_arn
  ecsServiceRole_arn  = data.terraform_remote_state.common.outputs.ecsServiceRole_arn
  cd_user_arn         = data.terraform_remote_state.common.outputs.codeship_arn
}

/*
 * Create Cloudwatch log group
 */
resource "aws_cloudwatch_log_group" "logs" {
  name              = "${var.app_name}-${data.terraform_remote_state.common.outputs.app_env}"
  retention_in_days = 30

  tags = {
    idp_name = var.idp_name
    app_env  = data.terraform_remote_state.common.outputs.app_env
  }
}

/*
 * Create target group for ALB
 */
resource "aws_alb_target_group" "tg" {
  name = replace(
    "tg-${var.app_name}-${data.terraform_remote_state.common.outputs.app_env}",
    "/(.{0,32})(.*)/",
    "$1",
  )
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
}

/*
 *  Create cloudwatch dashboard for service
 */
module "ecs-service-cloudwatch-dashboard" {
  source  = "silinternational/ecs-service-cloudwatch-dashboard/aws"
  version = "~> 2.0.0"

  cluster_name   = data.terraform_remote_state.common.outputs.ecs_cluster_name
  dashboard_name = "${var.app_name}-${data.terraform_remote_state.common.outputs.app_env}"
  service_names  = [var.app_name]
  aws_region     = var.aws_region
}

/*
 * Create Elasticache subnet group
 */
resource "aws_elasticache_subnet_group" "memcache_subnet_group" {
  name       = "${var.app_name}-${data.terraform_remote_state.common.outputs.app_env}"
  subnet_ids = data.terraform_remote_state.common.outputs.private_subnet_ids
}

/*
 * Create Cluster
 */
resource "aws_elasticache_cluster" "memcache" {
  cluster_id           = "${var.app_name}-${data.terraform_remote_state.common.outputs.app_env}"
  engine               = "memcached"
  node_type            = var.memcache_node_type
  port                 = var.memcache_port
  num_cache_nodes      = var.memcache_num_cache_nodes
  parameter_group_name = var.memcache_parameter_group_name
  security_group_ids   = [data.terraform_remote_state.common.outputs.vpc_default_sg_id]
  subnet_group_name    = aws_elasticache_subnet_group.memcache_subnet_group.name
  az_mode              = var.memcache_az_mode

  tags = {
    "app_name" = var.app_name
    "app_env"  = data.terraform_remote_state.common.outputs.app_env
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
    app_env                   = data.terraform_remote_state.common.outputs.app_env
    app_name                  = var.app_name
    aws_region                = var.aws_region
    cloudwatch_log_group_name = aws_cloudwatch_log_group.logs.name
    cloudflare_domain         = var.cloudflare_domain
    cpu                       = var.cpu
    docker_image              = module.ecr.repo_url
    docker_tag                = var.docker_tag
    help_center_url           = var.help_center_url
    idp_display_name          = var.idp_display_name
    idp_name                  = var.idp_name
    memcache_host1            = aws_elasticache_cluster.memcache.cache_nodes[0].address
    memcache_host2            = aws_elasticache_cluster.memcache.cache_nodes[1].address
    memory                    = var.memory
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
  source             = "github.com/silinternational/terraform-modules//aws/ecs/service-only?ref=3.5.0"
  cluster_id         = data.terraform_remote_state.common.outputs.ecs_cluster_id
  service_name       = var.app_name
  service_env        = data.terraform_remote_state.common.outputs.app_env
  container_def_json = data.template_file.task_def_hub.rendered
  desired_count      = var.desired_count
  tg_arn             = aws_alb_target_group.tg.arn
  lb_container_name  = "hub"
  lb_container_port  = "80"
  ecsServiceRole_arn = data.terraform_remote_state.common.outputs.ecsServiceRole_arn
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
