terraform {
  backend "s3" {
    bucket       = "devsecops-demo-tfstate-491085399161"
    key          = "ecs/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}