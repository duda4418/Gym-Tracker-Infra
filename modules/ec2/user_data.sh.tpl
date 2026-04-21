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
# they can address each other by container name (e.g. otel-collector, loki).
docker network create gym-tracker-net 2>/dev/null || true

# Clone infra repo to access Nginx hardening script
cd /tmp && git clone --depth 1 https://github.com/duda4418/Gym-Tracker-Infra.git

# ---------------------------------------------------------------------------
# Nginx — initial HTTP-only config so Certbot HTTP-01 challenge can succeed
# ---------------------------------------------------------------------------
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
# ---------------------------------------------------------------------------
# Observability stack — Grafana, Prometheus, Loki, Tempo, Pyroscope,
# OTEL Collector, Alertmanager, Promtail.
# All containers join gym-tracker-net so the backend can reach them by name.
# ---------------------------------------------------------------------------

# Resolve region via IMDSv2
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

# Pull secrets from SSM Parameter Store
GRAFANA_ADMIN_PASSWORD=$(aws ssm get-parameter \
  --region "$AWS_REGION" \
  --name "${obs_grafana_admin_password_ssm_param}" \
  --with-decryption \
  --query Parameter.Value \
  --output text)

ALERTMANAGER_AUTH_PASSWORD=$(aws ssm get-parameter \
  --region "$AWS_REGION" \
  --name "${obs_alertmanager_email_password_ssm_param}" \
  --with-decryption \
  --query Parameter.Value \
  --output text)

# Clone app repo for observability config files
# Expected at repo root: otel-collector-config.yml, tempo/, loki/, grafana/,
# promtail/, alertmanager.yml, alertmanager-entrypoint.sh, prometheus/ (rules)
git clone --depth 1 --branch ${obs_config_repo_branch} ${obs_config_repo_url} /tmp/gym-tracker-src

cd /opt/gym-tracker/observability

cp    /tmp/gym-tracker-src/otel-collector-config.yml .
cp -r /tmp/gym-tracker-src/tempo .
cp -r /tmp/gym-tracker-src/loki .
cp -r /tmp/gym-tracker-src/promtail .
cp    /tmp/gym-tracker-src/alertmanager.yml .
cp    /tmp/gym-tracker-src/alertmanager-entrypoint.sh .
chmod +x alertmanager-entrypoint.sh
cp -r /tmp/gym-tracker-src/grafana .

if [ -d /tmp/gym-tracker-src/prometheus ]; then
  cp -r /tmp/gym-tracker-src/prometheus .
else
  mkdir -p prometheus
fi

# Prometheus config — scrapes the backend container by name on gym-tracker-net
cat > prometheus.yml <<'PROMEOF'
global:
  scrape_interval:     15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'gym-tracker-backend'
    static_configs:
      - targets: ['gym-tracker-backend:8000']
    metrics_path: /metrics

  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8888']
PROMEOF

# Secrets env file — shell expands $GRAFANA_ADMIN_PASSWORD / $ALERTMANAGER_AUTH_PASSWORD
# at runtime; Terraform fills in the static values at plan time.
cat > .env <<ENVEOF
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD
GF_USERS_ALLOW_SIGN_UP=false
ALERTMANAGER_SMARTHOST=${obs_alertmanager_smarthost}
ALERTMANAGER_EMAIL_FROM=${obs_alertmanager_email_from}
ALERTMANAGER_EMAIL_TO=${obs_alertmanager_email_to}
ALERTMANAGER_AUTH_USERNAME=${obs_alertmanager_auth_username}
ALERTMANAGER_AUTH_PASSWORD=$ALERTMANAGER_AUTH_PASSWORD
ENVEOF

chmod 600 .env

# Docker Compose — single-quoted COMPOSEEOF so the shell doesn't expand anything.
# All services join gym-tracker-net (external) so the backend containers
# can reach otel-collector, loki, pyroscope etc. by name, and vice versa.
cat > docker-compose.yml <<'COMPOSEEOF'
networks:
  gym-tracker-net:
    external: true

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.123.0
    container_name: gym-tracker-otel-collector
    restart: unless-stopped
    depends_on:
      - tempo
    command:
      - "--config=/etc/otelcol-contrib/config.yaml"
    networks: [gym-tracker-net]
    volumes:
      - ./otel-collector-config.yml:/etc/otelcol-contrib/config.yaml:ro

  tempo:
    image: grafana/tempo:2.7.2
    container_name: gym-tracker-tempo
    restart: unless-stopped
    command:
      - "-config.file=/etc/tempo/tempo.yml"
    networks: [gym-tracker-net]
    volumes:
      - ./tempo/tempo.yml:/etc/tempo/tempo.yml:ro
      - tempo_data:/var/tempo

  loki:
    image: grafana/loki:3.2.1
    container_name: gym-tracker-loki
    restart: unless-stopped
    command:
      - "-config.file=/etc/loki/local-config.yaml"
    networks: [gym-tracker-net]
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
      - loki_data:/loki

  pyroscope:
    image: grafana/pyroscope:1.12.0
    container_name: gym-tracker-pyroscope
    restart: unless-stopped
    command:
      - "-target=all"
      - "-server.http-listen-port=4040"
      - "-storage.backend=filesystem"
      - "-storage.filesystem.dir=/var/lib/pyroscope"
      - "-usage-stats.enabled=false"
    networks: [gym-tracker-net]
    volumes:
      - pyroscope_data:/var/lib/pyroscope

  promtail:
    image: grafana/promtail:3.2.1
    container_name: gym-tracker-promtail
    restart: unless-stopped
    depends_on:
      - loki
    command:
      - "-config.file=/etc/promtail/config.yml"
    networks: [gym-tracker-net]
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml:ro
      - /opt/gym-tracker/backend/app/logs:/var/log/gym-tracker:ro

  prometheus:
    image: prom/prometheus
    container_name: gym-tracker-prometheus
    restart: unless-stopped
    networks: [gym-tracker-net]
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus:/etc/prometheus/rules:ro
      - prometheus_data:/prometheus

  alertmanager:
    image: prom/alertmanager
    container_name: gym-tracker-alertmanager
    restart: unless-stopped
    entrypoint:
      - /bin/sh
      - /etc/alertmanager/entrypoint.sh
    env_file:
      - .env
    networks: [gym-tracker-net]
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - ./alertmanager-entrypoint.sh:/etc/alertmanager/entrypoint.sh:ro

  grafana:
    image: grafana/grafana:11.1.0
    container_name: gym-tracker-grafana
    restart: unless-stopped
    depends_on:
      - prometheus
      - alertmanager
      - tempo
      - loki
      - pyroscope
    env_file:
      - .env
    ports:
      - "3005:3000"
    networks: [gym-tracker-net]
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro

volumes:
  grafana_data:
  pyroscope_data:
  tempo_data:
  loki_data:
  prometheus_data:
COMPOSEEOF

docker compose up -d
%{ endif }
