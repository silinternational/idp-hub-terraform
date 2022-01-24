data "terraform_remote_state" "common" {
  backend = "remote"

  config = {
    organization = var.tf_remote_organization
    name         = var.tf_remote_name
  }
}
