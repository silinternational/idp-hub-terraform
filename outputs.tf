
output "ssp_admin_pass" {
  value = random_id.ssp_admin_pass.hex
}

output "ssp_secret_salt" {
  value = random_id.ssp_secret_salt.hex
}

output "url" {
  value = "https://${var.subdomain}.${var.cloudflare_domain}"
}

output "cd_user_access_key_id" {
  value = module.app.cd_user_access_key_id
}

output "cd_user_secret_access_key_id" {
  value     = module.app.cd_user_secret_access_key_id
  sensitive = true
}

output "cd_user_arn" {
  value = local.create_cd_user ? module.app.cd_user_arn : var.cd_user_arn
}

output "user_log_table" {
  value = aws_dynamodb_table.logger.name
}

output "user_log_access_key_id" {
  value = aws_iam_access_key.user_login_logger.id
}

output "user_log_secret_access_key" {
  value     = aws_iam_access_key.user_login_logger.secret
  sensitive = true
}
