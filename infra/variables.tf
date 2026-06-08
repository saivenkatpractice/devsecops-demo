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