#!/bin/bash

CONTAINER_NAME=${1:-my-container}
IMAGE=${2:-nginx:alpine}
PORT=${3:-8080:80}

echo "Generation du service pour $CONTAINER_NAME"

podman create --name "$CONTAINER_NAME" -p "$PORT" "$IMAGE"
podman generate systemd --new --files --name "$CONTAINER_NAME"

echo "[OK] Fichier genere: container-$CONTAINER_NAME.service"
