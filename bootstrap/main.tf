terraform {
	required_version = ">= 1.6.0"

	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 5.0"
		}
	}
}

provider "aws" {
	region = var.aws_region
}

locals {
	github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
}

resource "aws_s3_bucket" "terraform_state" {
	bucket        = var.state_bucket_name
	force_destroy = false

	tags = merge(var.tags, {
		Name = var.state_bucket_name
	})
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
	bucket = aws_s3_bucket.terraform_state.id

	block_public_acls       = true
	block_public_policy     = true
	ignore_public_acls      = true
	restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
	bucket = aws_s3_bucket.terraform_state.id

	versioning_configuration {
		status = "Enabled"
	}
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
	bucket = aws_s3_bucket.terraform_state.id

	rule {
		apply_server_side_encryption_by_default {
			sse_algorithm = "AES256"
		}
	}
}

data "aws_iam_policy_document" "enforce_tls" {
	statement {
		sid    = "DenyInsecureTransport"
		effect = "Deny"

		principals {
			type        = "*"
			identifiers = ["*"]
		}

		actions = ["s3:*"]

		resources = [
			aws_s3_bucket.terraform_state.arn,
			"${aws_s3_bucket.terraform_state.arn}/*"
		]

		condition {
			test     = "Bool"
			variable = "aws:SecureTransport"
			values   = ["false"]
		}
	}
}

resource "aws_s3_bucket_policy" "terraform_state" {
	bucket = aws_s3_bucket.terraform_state.id
	policy = data.aws_iam_policy_document.enforce_tls.json
}

resource "aws_dynamodb_table" "terraform_locks" {
	count = var.create_dynamodb_lock_table ? 1 : 0

	name         = var.lock_table_name
	billing_mode = "PAY_PER_REQUEST"
	hash_key     = "LockID"

	attribute {
		name = "LockID"
		type = "S"
	}

	tags = merge(var.tags, {
		Name = var.lock_table_name
	})
}

resource "aws_iam_openid_connect_provider" "github" {
	count = var.create_github_oidc_provider ? 1 : 0

	url             = var.github_oidc_url
	client_id_list  = var.github_oidc_client_ids
	thumbprint_list = var.github_oidc_thumbprints
}

data "aws_iam_policy_document" "infra_assume_role" {
	count = var.create_infra_github_role ? 1 : 0

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
	count = var.create_infra_github_role ? 1 : 0

	name               = var.infra_role_name
	assume_role_policy = data.aws_iam_policy_document.infra_assume_role[0].json
	tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "infra" {
	for_each = var.create_infra_github_role ? toset(var.infra_role_policy_arns) : toset([])

	role       = aws_iam_role.infra[0].name
	policy_arn = each.value
}
