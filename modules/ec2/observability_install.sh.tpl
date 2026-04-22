#!/bin/bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  dnf install -y docker
fi

if ! command -v aws >/dev/null 2>&1; then
  dnf install -y awscli
fi

if ! command -v git >/dev/null 2>&1; then
  dnf install -y git
fi

systemctl enable docker
systemctl start docker

ensure_compose() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
    return 0
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
    return 0
  fi

  dnf install -y docker-compose-plugin || true

  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
    return 0
  fi

  compose_arch=$(uname -m)
  case "$compose_arch" in
    x86_64)
      compose_arch="x86_64"
      ;;
    aarch64|arm64)
      compose_arch="aarch64"
      ;;
    *)
      echo "Unsupported architecture for docker-compose: $compose_arch" >&2
      exit 1
      ;;
  esac

  curl -fsSL "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-$compose_arch" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
    return 0
  fi

  echo "Docker Compose is required but could not be installed." >&2
  exit 1
}

ensure_compose

mkdir -p /opt/gym-tracker/backend/app/logs
mkdir -p /opt/gym-tracker/backend/app/uploads
mkdir -p /opt/gym-tracker/observability
docker network create gym-tracker-net 2>/dev/null || true

IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

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

SOURCE_DIR=$(mktemp -d /tmp/gym-tracker-observability-src.XXXXXX)
cleanup() {
  rm -rf "$SOURCE_DIR"
}
trap cleanup EXIT

git clone --depth 1 --branch ${obs_config_repo_branch} ${obs_config_repo_url} "$SOURCE_DIR"

for required_path in \
  otel-collector-config.yml \
  alertmanager.yml \
  alertmanager-entrypoint.sh \
  grafana \
  loki \
  promtail \
  tempo; do
  if [ ! -e "$SOURCE_DIR/$required_path" ]; then
    echo "Missing required observability asset: $required_path" >&2
    exit 1
  fi
done

cd /opt/gym-tracker/observability
rm -rf tempo loki promtail grafana prometheus

cp "$SOURCE_DIR/otel-collector-config.yml" .
cp -r "$SOURCE_DIR/tempo" .
cp -r "$SOURCE_DIR/loki" .
cp -r "$SOURCE_DIR/promtail" .
cp "$SOURCE_DIR/alertmanager.yml" .
cp "$SOURCE_DIR/alertmanager-entrypoint.sh" .
chmod +x alertmanager-entrypoint.sh
cp -r "$SOURCE_DIR/grafana" .

if [ -d "$SOURCE_DIR/prometheus" ]; then
  cp -r "$SOURCE_DIR/prometheus" .
else
  mkdir -p prometheus
fi

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

"$${COMPOSE_CMD[@]}" up -d --remove-orphans