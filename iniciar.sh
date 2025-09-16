#!/bin/bash
set -e

# Verifica se o dialog está instalado
if ! command -v dialog &>/dev/null; then
    echo "dialog não encontrado. Instale com: sudo apt-get install dialog -y"
    exit 1
fi

# Perguntar quantidade de câmeras
NUM_CAMERAS=$(dialog --stdout --inputbox "Quantas câmeras deseja configurar?" 10 40 2)

if ! [[ "$NUM_CAMERAS" =~ ^[0-9]+$ ]] || [ "$NUM_CAMERAS" -lt 1 ]; then
    echo "Número inválido de câmeras!"
    exit 1
fi

# Limpar e criar novo .env
> .env

# Perguntar URLs de cada câmera
for i in $(seq 1 $NUM_CAMERAS); do
    URL=$(dialog --stdout --inputbox "Digite a URL RTSP da câmera $i:" 10 70)
    if [ -n "$URL" ]; then
        echo "CAMERA${i}=$URL" >> .env
    else
        echo "Nenhuma URL fornecida para câmera $i. Abortando."
        exit 1
    fi
done

# Rodar generate-compose
chmod +x generate-compose.sh
echo "Gerando arquivos docker-compose.yml e nginx.conf..."
./generate-compose.sh

# Limpar containers parados
echo "Limpando containers parados..."
docker container prune -f

# Subir serviços
echo "Iniciando containers..."
docker compose up -d --build

# Descobrir hostname/ip (padrão: cameras)
HOSTNAME="cameras"
if hostname -I >/dev/null 2>&1; then
    IP=$(hostname -I | awk '{print $1}')
else
    IP="localhost"
fi

# Montar lista de URLs para o menu
MENU_ITEMS=()
for i in $(seq 1 $NUM_CAMERAS); do
    PORT=$((9000 + i))
    URL="https://${HOSTNAME}:cam$i/"
    MENU_ITEMS+=("Cam${i}" "$URL")
done

# Mostrar menu final
dialog --title "Links das Câmeras" --menu "Selecione uma câmera para visualizar:" 20 70 10 "${MENU_ITEMS[@]}"

clear
echo "Configuração concluída!"
echo "Câmeras disponíveis:"
for i in $(seq 1 $NUM_CAMERAS); do
    PORT=$((9000 + i))
    echo "Cam$i → https://${HOSTNAME}:cam$i/"
done

