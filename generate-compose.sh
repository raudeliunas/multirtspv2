#!/bin/bash
set -e

# Carregar variáveis do .env
if [ ! -f .env ]; then
  echo "Arquivo .env não encontrado!"
  exit 1
fi

# Carregar todas as linhas que começam com CAMERA
declare -a CAMERAS
while IFS= read -r line; do
  if [[ $line =~ ^CAMERA[0-9]+=(.*)$ ]]; then
    CAMERAS+=("${BASH_REMATCH[1]}")
  fi
done < .env

if [ ${#CAMERAS[@]} -eq 0 ]; then
  echo "Nenhuma câmera encontrada no .env"
  exit 1
fi

COMPOSE_FILE="docker-compose.yml"
NGINX_FILE="nginx.conf"

# Cabeçalho docker-compose
cat > "$COMPOSE_FILE" <<EOL
version: "3.9"

services:
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./html:/var/www/html
      - ./certs:/etc/nginx/certs
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "443:443"
    depends_on:
EOL

# Adiciona dependências do nginx
for i in "${!CAMERAS[@]}"; do
  INDEX=$((i+1))
  echo "      - vlc_stream${INDEX}" >> "$COMPOSE_FILE"
done

# Criar serviços vlc_stream
for i in "${!CAMERAS[@]}"; do
  INDEX=$((i+1))
  EXT_PORT=$((8000 + INDEX))
  RTSP_URL="${CAMERAS[$i]}"

  cat >> "$COMPOSE_FILE" <<EOL

  vlc_stream${INDEX}:
    container_name: vlc_stream${INDEX}
    build:
      context: .
      dockerfile: Dockerfile.vlc
    restart: unless-stopped
    environment:
      - RTSP_URL=${RTSP_URL}
      - STREAM_PORT=8080
    ports:
      - "${EXT_PORT}:8080"
EOL
done

# Adicionar watchdog único
cat >> "$COMPOSE_FILE" <<EOL

  watchdog:
    build:
      context: .
      dockerfile: Dockerfile.watchdog
    container_name: watchdog
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
EOL

for i in "${!CAMERAS[@]}"; do
  INDEX=$((i+1))
  echo "      - vlc_stream${INDEX}" >> "$COMPOSE_FILE"
done

# Criar nginx.conf
cat > "$NGINX_FILE" <<EOL
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    server {
        listen 443 ssl;
        server_name localhost;

        ssl_certificate /etc/nginx/certs/server.crt;
        ssl_certificate_key /etc/nginx/certs/server.key;
EOL

# Adicionar rotas do nginx para cada câmera
for i in "${!CAMERAS[@]}"; do
  INDEX=$((i+1))
  cat >> "$NGINX_FILE" <<EOL
        location /cam${INDEX}/ {
            proxy_pass http://vlc_stream${INDEX}:8080/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
        }

EOL
done

# Adicionar rotas de certificado
cat >> "$NGINX_FILE" <<EOL
        location /certificado.html {
            root /var/www/html;
            index certificado.html;
        }

        location /certs/ {
            alias /etc/nginx/certs/;
            autoindex on;
        }
    }
}
EOL

echo "docker-compose.yml e nginx.conf gerados com sucesso!"
