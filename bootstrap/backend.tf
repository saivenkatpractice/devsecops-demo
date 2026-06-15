# Separate state file in the SAME bucket as the app infra.
# Key is "bootstrap/..." (app infra uses "ecs/..."), so a `terraform destroy`
# of the app NEVER touches the OIDC provider or the deploy role.
terraform {
  backend "s3" {
    bucket       = "devsecops-demo-tfstate-491085399161"
    key          = "bootstrap/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}