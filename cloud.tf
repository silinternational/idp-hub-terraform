terraform {
  cloud {
    organization = "gtis"
    workspaces {
      tags = ["app:idp-hub"]
    }
  }
}
