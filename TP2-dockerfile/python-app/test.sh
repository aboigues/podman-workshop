#!/bin/bash
echo "Test Python App"

EXIT_CODE=0

if ! podman build -t python-app-test .; then
    echo "[ERREUR] Build echoue"
    exit 1
fi

if ! podman run -d --name python-app-test -p 5001:5000 python-app-test; then
    echo "[ERREUR] Impossible de demarrer le conteneur"
    podman rmi python-app-test
    exit 1
fi

echo "Attente demarrage conteneur..."
sleep 5

if curl -s http://localhost:5001/api/health | grep -q "healthy"; then
    echo "[OK] Python app fonctionne"
else
    echo "[ERREUR] Python app ne repond pas"
    echo "Logs du conteneur:"
    podman logs python-app-test
    EXIT_CODE=1
fi

podman stop python-app-test
podman rm python-app-test
podman rmi python-app-test

exit $EXIT_CODE
