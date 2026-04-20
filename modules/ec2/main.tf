resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y docker awscli
    dnf install -y docker-compose-plugin || true

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ec2-user || true

    mkdir -p /opt/gym-tracker
    mkdir -p /opt/gym-tracker/frontend
    mkdir -p /opt/gym-tracker/backend
    mkdir -p /opt/gym-tracker/observability
    chown -R ec2-user:ec2-user /opt/gym-tracker
  EOT

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
