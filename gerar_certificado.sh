#!/bin/bash
set -e

# Pasta de saída
CERT_DIR="./certs"
CERT_KEY="$CERT_DIR/server.key"
CERT_CRT="$CERT_DIR/server.crt"

# Criar diretório se não existir
mkdir -p "$CERT_DIR"

echo "Gerando certificado SSL autoassinado (1000 dias)..."

# Gerar certificado apenas se ainda não existir
if [ ! -f "$CERT_KEY" ] || [ ! -f "$CERT_CRT" ]; then
    openssl req -x509 -nodes -days 1000 -newkey rsa:2048 \
        -keyout "$CERT_KEY" -out "$CERT_CRT" \
        -subj "/CN=cameras" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,DNS:cameras"

    chmod 644 "$CERT_KEY" "$CERT_CRT"
    echo "Certificado gerado com sucesso em $CERT_DIR"
else
    echo "Certificado já existe, pulando geração."
fi
