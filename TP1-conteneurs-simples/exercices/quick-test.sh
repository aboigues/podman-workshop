#!/bin/bash

echo "Test rapide TP1"
echo "==============="

EXIT_CODE=0

echo "Lancement conteneur..."
podman run -d --name test-quick-nginx -p 8888:80 nginx:alpine
sleep 2

echo "Verification..."
if curl -s http://localhost:8888 > /dev/null; then
    echo "[OK] Conteneur accessible"
else
    echo "[ERREUR] Conteneur non accessible"
    EXIT_CODE=1
fi

echo "Logs..."
podman logs test-quick-nginx | head -n 3

echo "Nettoyage..."
podman stop test-quick-nginx
podman rm test-quick-nginx

if [ $EXIT_CODE -eq 0 ]; then
    echo "[OK] Test termine"
else
    echo "[ERREUR] Test echoue"
fi

exit $EXIT_CODE
