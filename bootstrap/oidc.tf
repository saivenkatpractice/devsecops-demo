# Look up the current account ID so we don't hardcode it in ARNs
data "aws_caller_identity" "current" {}

# ── 1. The OIDC identity provider ──────────────────────────────────────────
# This tells AWS to trust JSON Web Tokens minted by GitHub Actions.
# No thumbprint_list: since July 2023 AWS validates GitHub's IdP against its
# own library of trusted root CAs, and the AWS provider 6.x makes the field
# optional. (Older tutorials hardcode a 6938fd4... thumbprint that does nothing.)
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = {
    Name = "github-actions-oidc"
  }
}

# ── 2. Trust policy: WHO may assume the deploy role ─────────────────────────
# A GitHub workflow can assume this role ONLY if its OIDC token proves:
#   - audience (aud) is sts.amazonaws.com, AND
#   - subject (sub) is one of our exact, allow-listed contexts.
# The `sub` claim is how we pin to THIS repo and ONLY these contexts:
#   - the main branch (used by the build-and-push job), and
#   - the staging / production GitHub Environments (used by deploy jobs).
# Anything else (other repos, other branches, forks, PRs) is rejected by AWS.
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:environment:staging",
        "repo:${var.github_org}/${var.github_repo}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "${var.project_name}-github-actions"
  description          = "Assumed by GitHub Actions via OIDC to deploy ${var.project_name}"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600 # 1 hour

  tags = {
    Name = "${var.project_name}-github-actions"
  }
}

# ── 3. Permissions policy: WHAT the deploy role may do ──────────────────────
# Broad at the service level for the networking/compute the app needs, but the
# two genuinely dangerous areas — IAM and the Terraform state bucket — are
# tightly scoped by resource ARN.
data "aws_iam_policy_document" "github_actions_permissions" {

  # Build/push images + let Terraform manage the app infrastructure.
  statement {
    sid    = "AppInfra"
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecs:*",
      "ecr:*",
      "elasticloadbalancing:*",
      "logs:*",
    ]
    resources = ["*"]
  }

  # Manage ONLY this project's IAM roles (exec/task/flow-logs), and pass them
  # to ECS / VPC Flow Logs. Cannot touch any other role in the account.
  statement {
    sid    = "ProjectIamRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*",
    ]
  }

  # Allow ECS to create its service-linked role if the account doesn't have it.
  statement {
    sid       = "EcsServiceLinkedRole"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["ecs.amazonaws.com"]
    }
  }

  # Read/write the app's remote state object + the native S3 lock file.
  statement {
    sid       = "TerraformStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.tfstate_bucket}/*"]
  }

  statement {
    sid       = "TerraformStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tfstate_bucket}"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.project_name}-deploy-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}