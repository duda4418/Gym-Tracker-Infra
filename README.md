# Gym-Tracker-Infra

Simple Terraform infrastructure for the Gym Tracker project on AWS.

It bootstraps remote Terraform state, provisions the production stack, and supports GitHub Actions deployments for the backend and frontend.

## Tech Stack

- Terraform >= 1.6
- AWS: S3, DynamoDB, VPC, EC2, RDS, ECR, IAM, SSM, Route53, CloudWatch
- GitHub Actions with AWS OIDC
- Docker on EC2
- Nginx hardening scripts and optional observability tooling

## Main Features

- Bootstrap remote Terraform state in S3 with optional DynamoDB locking
- Reusable Terraform modules for network, security, IAM, EC2, RDS, ECR, DNS, and monitoring
- Production environment under `envs/prod`
- GitHub OIDC roles for least-privilege CI/CD access
- Backend deployment flow: build image, push to ECR, deploy to EC2 through SSM
- Secrets sourced from SSM Parameter Store instead of plaintext `tfvars`
- Optional observability stack for metrics, logs, traces, and profiling

## Project Structure

```text
.
|- bootstrap/     # Remote state bootstrap (S3, DynamoDB, OIDC infra role)
|- docs/          # Security notes and deployment workflow docs
|- envs/prod/     # Production entrypoint and variables
|- modules/       # Reusable Terraform modules
|- scripts/       # Host hardening helpers
```

## Quick Start

1. Bootstrap the Terraform backend from `bootstrap/`.
2. Review and update `envs/prod/terraform.tfvars`.
3. Create required SSM parameters for secrets before `apply`.
4. Run Terraform from `envs/prod/`:

```bash
terraform init
terraform plan
terraform apply
```

## Good Practices For This Repo

- Keep secrets in SSM or Secrets Manager, never in source control.
- Keep the backend app port private and expose only the reverse proxy publicly.
- Use least-privilege IAM roles for GitHub Actions and EC2.
- If observability is enabled, prefer at least a `t3.medium` instance.
