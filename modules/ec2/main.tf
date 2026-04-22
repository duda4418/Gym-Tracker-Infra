locals {
  observability_install_script = replace(templatefile("${path.module}/observability_install.sh.tpl", {
    obs_config_repo_url                       = coalesce(var.obs_config_repo_url, "")
    obs_config_repo_branch                    = var.obs_config_repo_branch
    obs_grafana_admin_password_ssm_param      = coalesce(var.obs_grafana_admin_password_ssm_param, "")
    obs_alertmanager_email_password_ssm_param = coalesce(var.obs_alertmanager_email_password_ssm_param, "")
    obs_alertmanager_smarthost                = var.obs_alertmanager_smarthost
    obs_alertmanager_email_from               = coalesce(var.obs_alertmanager_email_from, "")
    obs_alertmanager_email_to                 = coalesce(var.obs_alertmanager_email_to, "")
    obs_alertmanager_auth_username            = coalesce(var.obs_alertmanager_auth_username, "")
  }), "\r", "")
}

resource "terraform_data" "observability_install_revision" {
  count = var.enable_observability ? 1 : 0

  input = sha1(local.observability_install_script)
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    certbot_email                = var.certbot_email
    enable_observability         = var.enable_observability
    observability_install_script = local.observability_install_script
  })

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ec2"
  })
}

resource "aws_ssm_document" "observability_install" {
  count = var.enable_observability ? 1 : 0

  name            = "${var.project}-${var.environment}-observability-install"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Install or update the Gym Tracker observability stack on EC2."
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "installObservability"
        inputs = {
          runCommand = split("\n", local.observability_install_script)
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_ssm_association" "observability_install" {
  count = var.enable_observability ? 1 : 0

  name                = aws_ssm_document.observability_install[0].name
  association_name    = "${var.project}-${var.environment}-observability-install"
  document_version    = "$LATEST"
  max_concurrency     = "1"
  max_errors          = "1"
  wait_for_success_timeout_seconds = 900

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }

  lifecycle {
    replace_triggered_by = [terraform_data.observability_install_revision[0]]
  }
}

resource "aws_eip" "this" {
  count = var.create_elastic_ip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ec2-eip"
  })
}
