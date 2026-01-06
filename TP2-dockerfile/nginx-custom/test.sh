#!/bin/bash
echo "Test Nginx Custom"

EXIT_CODE=0

if ! podman build -t nginx-custom-test .; then
    echo "[ERREUR] Build echoue"
    exit 1
fi

if ! podman run -d --name nginx-custom-test -p 8083:80 nginx-custom-test; then
    echo "[ERREUR] Impossible de demarrer le conteneur"
    podman rmi nginx-custom-test
    exit 1
fi

echo "Attente demarrage conteneur..."
sleep 3

if curl -s http://localhost:8083/health | grep -q "healthy"; then
    echo "[OK] Nginx custom fonctionne"
else
    echo "[ERREUR] Nginx custom ne repond pas"
    echo "Logs du conteneur:"
    podman logs nginx-custom-test
    EXIT_CODE=1
fi

podman stop nginx-custom-test
podman rm nginx-custom-test
podman rmi nginx-custom-test

exit $EXIT_CODE
