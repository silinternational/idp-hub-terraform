# idp-hub-terraform

This is a Terraform root module defining a SimpleSAMLphp "hub". It is based on
[ssp-base](https://github.com/silinternational/ssp-base) which utilizes several custom SimpleSAMLphp
modules, providing a menu of Identity Provider (IdP) choices for a user to choose from. The hub acts
as an IdP to a number of Service Providers (SP) and as a SP to the chosen IDP. 

This root module creates and manages:

- VPC (Virtual Private Cloud)
- ASG (Autoscaling Group)
- ALB (Application Load Balancer)
- ECS (Elastic Container Service) Cluster
- CD (Continuous Deployment) IAM user
- RDS (Relational Database Service) MariaDB database for session storage
- Cloudwatch log group and optional dashboard
- ECR (Elastic Container Registry) with optional replication policy
- Optional Cloudflare DNS record
- Cloudtrail logging (audit logs)

## Using Terraform CLI

This repository includes a `cloud.tf` file to connect to the Terraform Cloud workspace that uses this repository.
That allows for using the Terraform CLI to do plan-only runs, i.e. `terraform plan`. To begin with, you would need
to run `terraform init` after cloning this repository. You will also need to supply provider credentials,
which can be provided in environment variables. To make this more convenient and less susceptible to unsafe handling
of credentials, you can use the included `op.env` file to automatically pull in the credentials from 1Password.

## Using 1Password CLI

1. Install the [1Password CLI](https://developer.1password.com/docs/cli/get-started#install).
2. Run `op signin` and enter your 1Password password when prompted.
3. Prefix any Terraform command with `op run --env-file=op.env`, e.g. `op run --env-file=op.env terraform plan` 
