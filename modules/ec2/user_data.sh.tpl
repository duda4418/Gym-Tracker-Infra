#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y docker awscli git
dnf install -y docker-compose-plugin || true

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user || true

mkdir -p /opt/gym-tracker/frontend
mkdir -p /opt/gym-tracker/backend/app/logs
mkdir -p /opt/gym-tracker/backend/app/uploads
mkdir -p /opt/gym-tracker/observability
chown -R ec2-user:ec2-user /opt/gym-tracker

# Shared Docker network — observability and app containers both join this so
docker network create gym-tracker-net 2>/dev/null || true

# Clone infra repo to access Nginx hardening script
cd /tmp && git clone --depth 1 https://github.com/duda4418/Gym-Tracker-Infra.git

# Nginx — initial HTTP-only config so Certbot HTTP-01 challenge can succeed
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

# ---------------------------------------------------------------------------
# Certbot — TLS certs for both domains
# ---------------------------------------------------------------------------
dnf install -y python3-certbot-nginx
certbot --nginx --non-interactive --agree-tos \
  --email ${certbot_email} \
  --domains api.gym-tracker.website \
  --redirect

certbot --nginx --non-interactive --agree-tos \
  --email ${certbot_email} \
  --domains gym-tracker.website,www.gym-tracker.website \
  --redirect

systemctl enable --now certbot-renew.timer

%{ if enable_observability }
cat > /opt/gym-tracker/observability/install_observability.sh <<'OBSEOF'
${observability_install_script}
OBSEOF

chmod 700 /opt/gym-tracker/observability/install_observability.sh
/opt/gym-tracker/observability/install_observability.sh
%{ endif }
