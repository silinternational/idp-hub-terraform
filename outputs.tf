output "ecr_repo_url" {
  value = module.ecr.repo_url
}

output "ssp_admin_pass" {
  value = random_id.ssp_admin_pass.hex
}

output "ssp_secret_salt" {
  value = random_id.ssp_secret_salt.hex
}

output "url" {
  value = "https://${var.subdomain}.${var.cloudflare_domain}"
}
