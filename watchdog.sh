#!/bin/bash

echo 'Watchdog iniciado. Monitorando containers vlc_stream...'

while true; do
    # Lista todos os containers que começam com "vlc_stream"
    for container in $(docker ps --format '{{.Names}}' | grep '^vlc_stream'); do
        if docker logs --tail=15 "$container" 2>&1 | grep -E -q "TEARDOWN|main stream error|nothing to play"; then
            echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') Reiniciando $container por erro detectado"
            docker restart "$container" >/dev/null
            sleep 15
        fi
    done
    sleep 10
done
