/*
 * Create ECR repo
 */
module "ecr" {
  source              = "github.com/silinternational/terraform-modules//aws/ecr?ref=2.2.0"
  repo_name           = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
  ecsInstanceRole_arn = "${data.terraform_remote_state.common.ecsInstanceRole_arn}"
  ecsServiceRole_arn  = "${data.terraform_remote_state.common.ecsServiceRole_arn}"
  cd_user_arn         = "${data.terraform_remote_state.common.codeship_arn}"
}

/*
 * Create Logentries log
 */
resource "logentries_log" "log" {
  logset_id = "${data.terraform_remote_state.common.logentries_set_id}"
  name      = "${var.app_name}"
  source    = "token"
}

/*
 * Create target group for ALB
 */
resource "aws_alb_target_group" "tg" {
  name                 = "${replace("tg-${var.app_name}-${data.terraform_remote_state.common.app_env}", "/(.{0,32})(.*)/", "$1")}"
  port                 = "80"
  protocol             = "HTTP"
  vpc_id               = "${data.terraform_remote_state.common.vpc_id}"
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
  listener_arn = "${data.terraform_remote_state.common.alb_https_listener_arn}"
  priority     = "217"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.tg.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.subdomain}.${var.cloudflare_domain}"]
  }
}

/*
 *  Create cloudwatch dashboard for service
 */
module "ecs-service-cloudwatch-dashboard" {
  source  = "silinternational/ecs-service-cloudwatch-dashboard/aws"
  version = "~> 1.0.0"

  cluster_name   = "${data.terraform_remote_state.common.ecs_cluster_name}"
  dashboard_name = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
  service_names  = ["${var.app_name}"]
  aws_region     = "${var.aws_region}"
}

/*
 * Create Memcache cluster for session handling
 */
module "memcache" {
  source             = "github.com/silinternational/terraform-modules//aws/elasticache/memcache?ref=2.2.0"
  cluster_id         = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
  security_group_ids = ["${data.terraform_remote_state.common.vpc_default_sg_id}"]
  subnet_group_name  = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
  subnet_ids         = ["${data.terraform_remote_state.common.private_subnet_ids}"]
  availability_zones = ["${data.terraform_remote_state.common.aws_zones}"]
  app_name           = "${var.app_name}"
  app_env            = "${data.terraform_remote_state.common.app_env}"
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
data "template_file" "task_def_web" {
  template = "${file("${path.module}/task-def-web.json")}"

  vars {
    admin_email       = "${var.admin_email}"
    admin_name        = "${var.admin_name}"
    admin_pass        = "${random_id.ssp_admin_pass.hex}"
    cloudflare_domain = "${var.cloudflare_domain}"
    cpu               = "${var.cpu}"
    docker_image      = "${module.ecr.repo_url}"
    docker_tag        = "${var.docker_tag}"
    idp_display_name  = "${var.idp_display_name}"
    idp_name          = "${var.idp_name}"
    logentries_key    = "${logentries_log.log.token}"
    memcache_host1    = "${module.memcache.cache_nodes.0.address}"
    memcache_host2    = "${module.memcache.cache_nodes.1.address}"
    memory            = "${var.memory}"
    secret_salt       = "${random_id.ssp_secret_salt.hex}"
    show_saml_errors  = "${var.show_saml_errors}"
    subdomain         = "${var.subdomain}"
  }
}

/*
 * Create new ecs service
 */
module "ecs" {
  source             = "github.com/silinternational/terraform-modules//aws/ecs/service-only?ref=2.2.0"
  cluster_id         = "${data.terraform_remote_state.common.ecs_cluster_id}"
  service_name       = "${var.app_name}"
  service_env        = "${data.terraform_remote_state.common.app_env}"
  container_def_json = "${data.template_file.task_def_web.rendered}"
  desired_count      = "${var.desired_count}"
  tg_arn             = "${aws_alb_target_group.tg.arn}"
  lb_container_name  = "hub"
  lb_container_port  = "80"
  ecsServiceRole_arn = "${data.terraform_remote_state.common.ecsServiceRole_arn}"
}

/*
 * Create Cloudflare DNS record
 */
resource "cloudflare_record" "dns" {
  count   = "${var.create_dns_entry}"
  domain  = "${var.cloudflare_domain}"
  name    = "${var.subdomain}"
  value   = "${data.terraform_remote_state.common.alb_dns_name}"
  type    = "CNAME"
  proxied = true
}
