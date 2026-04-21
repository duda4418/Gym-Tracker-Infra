resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    certbot_email = var.certbot_email

    enable_observability                      = var.enable_observability
    obs_config_repo_url                       = coalesce(var.obs_config_repo_url, "")
    obs_config_repo_branch                    = var.obs_config_repo_branch
    obs_grafana_admin_password_ssm_param      = coalesce(var.obs_grafana_admin_password_ssm_param, "")
    obs_alertmanager_email_password_ssm_param = coalesce(var.obs_alertmanager_email_password_ssm_param, "")
    obs_alertmanager_smarthost                = var.obs_alertmanager_smarthost
    obs_alertmanager_email_from               = coalesce(var.obs_alertmanager_email_from, "")
    obs_alertmanager_email_to                 = coalesce(var.obs_alertmanager_email_to, "")
    obs_alertmanager_auth_username            = coalesce(var.obs_alertmanager_auth_username, "")
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

resource "aws_eip" "this" {
  count = var.create_elastic_ip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ec2-eip"
  })
}
