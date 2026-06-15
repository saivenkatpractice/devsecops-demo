variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names"
  type        = string
  default     = "devsecops-demo"
}

variable "environment" {
  description = "Deployment environment (staging or production)"
  type        = string
  default     = "staging"
}

variable "image_tag" {
  description = "Container image tag to deploy (the Git short SHA). Required: no default, so a deploy must always name an explicit, immutable image."
  type        = string
}