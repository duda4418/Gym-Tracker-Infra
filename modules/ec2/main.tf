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
    dnf install -y docker awscli git
    dnf install -y docker-compose-plugin || true

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ec2-user || true

    mkdir -p /opt/gym-tracker/frontend
    mkdir -p /opt/gym-tracker/backend
    mkdir -p /opt/gym-tracker/observability
    chown -R ec2-user:ec2-user /opt/gym-tracker

    # Clone infra repo to access Nginx script
    cd /tmp && git clone --depth 1 https://github.com/duda4418/Gym-Tracker-Infra.git

    # Install Nginx and configure initial HTTP-only stubs so Certbot can complete
    # its HTTP-01 challenge before we have any TLS certs
    dnf install -y nginx
    systemctl enable nginx

    cat > /etc/nginx/conf.d/gym-tracker-backend.conf <<'NGINXEOF'
server {
    listen 80;
    listen [::]:80;
    server_name api.gym-tracker.website;

    location / {
        proxy_pass         http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
NGINXEOF

    cat > /etc/nginx/conf.d/gym-tracker-frontend.conf <<'NGINXEOF'
server {
    listen 80;
    listen [::]:80;
    server_name gym-tracker.website www.gym-tracker.website;

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_set_header   Upgrade           $http_upgrade;
        proxy_set_header   Connection        'upgrade';
    }
}
NGINXEOF

    nginx -t
    systemctl start nginx

    # Install Certbot and obtain real Let's Encrypt certs for both domains.
    # Certbot rewrites the conf files to add TLS + HTTP→HTTPS redirect automatically.
    dnf install -y python3-certbot-nginx
    certbot --nginx --non-interactive --agree-tos \
      --email ${var.certbot_email} \
      --domains api.gym-tracker.website \
      --redirect

    certbot --nginx --non-interactive --agree-tos \
      --email ${var.certbot_email} \
      --domains gym-tracker.website,www.gym-tracker.website \
      --redirect

    # Enable auto-renewal
    systemctl enable --now certbot-renew.timer
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
