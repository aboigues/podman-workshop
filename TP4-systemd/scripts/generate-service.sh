#!/bin/bash
# Script de génération de fichier Quadlet .container
#
# Usage: ./generate-service.sh CONTAINER_NAME [IMAGE] [PORT]
#
# Exemples:
#   ./generate-service.sh nginx
#   ./generate-service.sh myapp nginx:alpine 8080:80
#   ./generate-service.sh webapp python:3.12-slim 5000:5000

set -e

CONTAINER_NAME=${1:?Usage: $0 CONTAINER_NAME [IMAGE] [PORT]}
IMAGE=${2:-docker.io/library/nginx:alpine}
PORT=${3:-8080:80}

QUADLET_DIR="$HOME/.config/containers/systemd"
QUADLET_FILE="$QUADLET_DIR/$CONTAINER_NAME.container"

# Créer le répertoire Quadlet si nécessaire
mkdir -p "$QUADLET_DIR"

# Vérifier si le fichier existe déjà
if [ -f "$QUADLET_FILE" ]; then
    echo "[WARN] Le fichier $QUADLET_FILE existe déjà."
    read -p "Voulez-vous l'écraser? (o/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Annulé."
        exit 1
    fi
fi

# Générer le fichier Quadlet
cat > "$QUADLET_FILE" << EOF
[Unit]
Description=$CONTAINER_NAME container
After=network-online.target

[Container]
ContainerName=$CONTAINER_NAME
Image=$IMAGE
PublishPort=$PORT

[Service]
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

echo "[OK] Fichier Quadlet créé: $QUADLET_FILE"
echo ""
echo "Contenu généré:"
echo "----------------------------------------"
cat "$QUADLET_FILE"
echo "----------------------------------------"
echo ""
echo "Prochaines étapes:"
echo "  1. systemctl --user daemon-reload"
echo "  2. systemctl --user enable --now $CONTAINER_NAME"
echo "  3. systemctl --user status $CONTAINER_NAME"
echo ""
echo "Pour voir l'unité systemd générée:"
echo "  systemctl --user cat $CONTAINER_NAME"
