variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names"
  type        = string
  default     = "devsecops-demo"
}

variable "github_org" {
  description = "GitHub account/org that owns the repo"
  type        = string
  default     = "saivenkatpractice"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "devsecops-demo"
}

variable "tfstate_bucket" {
  description = "S3 bucket that holds Terraform remote state"
  type        = string
  default     = "devsecops-demo-tfstate-491085399161"
}