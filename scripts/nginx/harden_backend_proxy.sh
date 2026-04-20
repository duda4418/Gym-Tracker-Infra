#!/usr/bin/env bash
set -euo pipefail

# Hardens Nginx in front of a backend service on localhost.
# It configures:
# - HTTP reverse proxy on :80 (or HTTP->HTTPS redirect)
# - HTTPS reverse proxy on :443 using a self-signed cert if no cert exists
# - Basic per-IP request and connection rate limits

UPSTREAM_HOST="${UPSTREAM_HOST:-127.0.0.1}"
UPSTREAM_PORT="${UPSTREAM_PORT:-8000}"
TLS_SERVER_NAME="${TLS_SERVER_NAME:-localhost}"
FORCE_HTTPS_REDIRECT="${FORCE_HTTPS_REDIRECT:-false}"

API_RATE_LIMIT="${API_RATE_LIMIT:-10r/s}"
API_RATE_BURST="${API_RATE_BURST:-30}"
API_CONN_LIMIT="${API_CONN_LIMIT:-20}"
CLIENT_MAX_BODY_SIZE="${CLIENT_MAX_BODY_SIZE:-100m}"

TLS_CERT_PATH="${TLS_CERT_PATH:-/etc/nginx/ssl/gym-tracker-selfsigned.crt}"
TLS_KEY_PATH="${TLS_KEY_PATH:-/etc/nginx/ssl/gym-tracker-selfsigned.key}"

NGINX_CONF="/etc/nginx/conf.d/gym-tracker-backend.conf"

sudo dnf install -y nginx openssl
sudo mkdir -p /etc/nginx/ssl

if [[ ! -f "${TLS_CERT_PATH}" || ! -f "${TLS_KEY_PATH}" ]]; then
  sudo openssl req \
    -x509 \
    -newkey rsa:2048 \
    -sha256 \
    -days 90 \
    -nodes \
    -keyout "${TLS_KEY_PATH}" \
    -out "${TLS_CERT_PATH}" \
    -subj "/CN=${TLS_SERVER_NAME}" \
    -addext "subjectAltName=DNS:${TLS_SERVER_NAME}"
fi

if [[ "${FORCE_HTTPS_REDIRECT}" == "true" ]]; then
  sudo tee "${NGINX_CONF}" >/dev/null <<'EOF'
limit_req_zone \$binary_remote_addr zone=api_limit_per_ip:10m rate=${API_RATE_LIMIT};
limit_conn_zone \$binary_remote_addr zone=api_conn_per_ip:10m;

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

upstream backend_upstream {
    server ${UPSTREAM_HOST}:${UPSTREAM_PORT};
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    server_name _;

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name _;

    ssl_certificate ${TLS_CERT_PATH};
    ssl_certificate_key ${TLS_KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;

    client_max_body_size ${CLIENT_MAX_BODY_SIZE};

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy no-referrer always;

    location / {
        limit_req zone=api_limit_per_ip burst=${API_RATE_BURST} nodelay;
        limit_conn api_conn_per_ip ${API_CONN_LIMIT};

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        proxy_pass http://backend_upstream;
    }
}
EOF
else
  sudo tee "${NGINX_CONF}" >/dev/null <<'EOF'
limit_req_zone \$binary_remote_addr zone=api_limit_per_ip:10m rate=${API_RATE_LIMIT};
limit_conn_zone \$binary_remote_addr zone=api_conn_per_ip:10m;

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

upstream backend_upstream {
    server ${UPSTREAM_HOST}:${UPSTREAM_PORT};
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    server_name _;

    client_max_body_size ${CLIENT_MAX_BODY_SIZE};

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy no-referrer always;

    location / {
        limit_req zone=api_limit_per_ip burst=${API_RATE_BURST} nodelay;
        limit_conn api_conn_per_ip ${API_CONN_LIMIT};

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        proxy_pass http://backend_upstream;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name _;

    ssl_certificate ${TLS_CERT_PATH};
    ssl_certificate_key ${TLS_KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;

    client_max_body_size ${CLIENT_MAX_BODY_SIZE};

    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header Referrer-Policy no-referrer always;

    location / {
        limit_req zone=api_limit_per_ip burst=${API_RATE_BURST} nodelay;
        limit_conn api_conn_per_ip ${API_CONN_LIMIT};

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        proxy_pass http://backend_upstream;
    }
}
EOF
fi

sudo rm -f /etc/nginx/conf.d/default.conf || true
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

echo "Nginx backend hardening applied."
