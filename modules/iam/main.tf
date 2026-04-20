locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
  create_ec2_runtime_secrets_policy = length(var.ec2_ssm_parameter_arns) > 0 || length(var.ec2_secretsmanager_secret_arns) > 0 || length(var.ec2_kms_key_arns) > 0
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = var.github_oidc_url
  client_id_list  = var.github_oidc_client_ids
  thumbprint_list = var.github_oidc_thumbprints
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.infra_role_subject]
    }
  }
}

resource "aws_iam_role" "infra" {
  name               = var.infra_role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "infra" {
  for_each = toset(var.infra_role_policy_arns)

  role       = aws_iam_role.infra.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "frontend_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.frontend_role_subject]
    }
  }
}

resource "aws_iam_role" "frontend" {
  name               = var.frontend_role_name
  assume_role_policy = data.aws_iam_policy_document.frontend_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "frontend" {
  for_each = toset(var.frontend_role_policy_arns)

  role       = aws_iam_role.frontend.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "backend_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.backend_role_subject]
    }
  }
}

resource "aws_iam_role" "backend" {
  name               = var.backend_role_name
  assume_role_policy = data.aws_iam_policy_document.backend_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend" {
  for_each = toset(var.backend_role_policy_arns)

  role       = aws_iam_role.backend.name
  policy_arn = each.value
}

resource "aws_iam_role" "ec2" {
  name = var.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "ec2" {
  name = var.ec2_instance_profile_name
  role = aws_iam_role.ec2.name

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_managed" {
  for_each = toset(var.ec2_managed_policy_arns)

  role       = aws_iam_role.ec2.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "ec2_runtime_secrets" {
  count = local.create_ec2_runtime_secrets_policy ? 1 : 0

  dynamic "statement" {
    for_each = length(var.ec2_ssm_parameter_arns) > 0 ? [1] : []

    content {
      sid       = "AllowReadRuntimeSsmParameters"
      actions   = ["ssm:GetParameter", "ssm:GetParameters"]
      resources = var.ec2_ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.ec2_secretsmanager_secret_arns) > 0 ? [1] : []

    content {
      sid       = "AllowReadRuntimeSecretsManagerSecrets"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.ec2_secretsmanager_secret_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.ec2_kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "AllowDecryptRuntimeSecretKeys"
      actions   = ["kms:Decrypt"]
      resources = var.ec2_kms_key_arns
    }
  }
}

resource "aws_iam_policy" "ec2_runtime_secrets" {
  count = local.create_ec2_runtime_secrets_policy ? 1 : 0

  name        = "${var.ec2_role_name}-runtime-secrets-read"
  description = "Least-privilege runtime secret read for Gym Tracker EC2 deploys."
  policy      = data.aws_iam_policy_document.ec2_runtime_secrets[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_runtime_secrets" {
  count = local.create_ec2_runtime_secrets_policy ? 1 : 0

  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_runtime_secrets[0].arn
}
