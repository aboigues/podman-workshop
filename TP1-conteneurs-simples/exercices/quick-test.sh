#!/bin/bash

echo "Test rapide TP1"
echo "==============="

echo "Lancement conteneur..."
podman run -d --name test-quick-nginx -p 8888:80 nginx:alpine
sleep 2

echo "Verification..."
if curl -s http://localhost:8888 > /dev/null; then
    echo "[OK] Conteneur accessible"
else
    echo "[ERREUR] Conteneur non accessible"
fi

echo "Logs..."
podman logs test-quick-nginx | head -n 3

echo "Nettoyage..."
podman stop test-quick-nginx
podman rm test-quick-nginx

echo "[OK] Test termine"
