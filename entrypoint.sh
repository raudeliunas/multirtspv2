#!/bin/sh

# Definição de variáveis
CERT_DIR="/certs"
CERT_KEY="$CERT_DIR/server.key"
CERT_CRT="$CERT_DIR/server.crt"

# Criar diretório de certificados se não existir
mkdir -p "$CERT_DIR"

# Gerar certificado SSL se não existir
if [ ! -f "$CERT_KEY" ] || [ ! -f "$CERT_CRT" ]; then
    echo "Gerando certificado SSL autoassinado..."
    openssl req -x509 -nodes -days 1000 -newkey rsa:2048 \
        -keyout "$CERT_KEY" -out "$CERT_CRT" \
        -subj "/CN=cameras" \
        -addext "subjectAltName = DNS:localhost, DNS:127.0.0.1, DNS:cameras"
else
    echo "Certificado SSL já existe. Pulando geração."
fi

# Ajustar permissões para que o Nginx possa acessar os arquivos
chmod 644 "$CERT_CRT" "$CERT_KEY"

# Verificar se as variáveis de ambiente necessárias estão definidas
if [ -z "$RTSP_URL1" ] || [ -z "$STREAM_PORT1" ]; then
    echo "Erro: RTSP_URL ou STREAM_PORT não estão definidos."
    exit 1
fi

# Verificar se as variáveis de ambiente necessárias estão definidas
if [ -z "$RTSP_URL2" ] || [ -z "$STREAM_PORT2" ]; then
    echo "Erro: RTSP_URL ou STREAM_PORT não estão definidos."
    exit 1
fi

# Criar usuário para rodar VLC se não existir
if ! id "vlcuser" >/dev/null 2>&1; then
    echo "Criando usuário vlcuser..."
    adduser -D -H -u 1000 vlcuser
fi

# Iniciar VLC com os parâmetros corretos
echo "Iniciando VLC..."
exec su-exec vlcuser cvlc -vvv "$RTSP_URL1" \
    --sout "#transcode{vcodec=MJPG,venc=ffmpeg{strict=1},fps=2,width=640,height=480}:standard{access=http{mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=0.0.0.0:$STREAM_PORT1/}" \
    --no-sout-all --sout-keep --no-daemon

# Iniciar VLC com os parâmetros corretos
echo "Iniciando VLC..."
exec su-exec vlcuser cvlc -vvv "$RTSP_URL2" \
    --sout "#transcode{vcodec=MJPG,venc=ffmpeg{strict=1},fps=2,width=640,height=480}:standard{access=http{mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=0.0.0.0:$STREAM_PORT2/}" \
    --no-sout-all --sout-keep --no-daemon
