output "github_actions_role_arn" {
  description = "ARN of the role GitHub Actions assumes via OIDC (put this in cd.yml)"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
}