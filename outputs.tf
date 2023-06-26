
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

output "user_log_table" {
  value = aws_dynamodb_table.logger.name
}
