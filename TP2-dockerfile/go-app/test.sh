#!/bin/bash
echo "Test Go App"

EXIT_CODE=0

if ! podman build -t go-app-test .; then
    echo "[ERREUR] Build echoue"
    exit 1
fi

if ! podman run -d --name go-app-test -p 8081:8080 go-app-test; then
    echo "[ERREUR] Impossible de demarrer le conteneur"
    podman rmi go-app-test
    exit 1
fi

echo "Attente demarrage conteneur..."
sleep 5

if curl -s http://localhost:8081/api/health | grep -q "healthy"; then
    echo "[OK] Go app fonctionne"
    SIZE=$(podman images go-app-test --format "{{.Size}}")
    echo "Taille image: $SIZE"
else
    echo "[ERREUR] Go app ne repond pas"
    echo "Logs du conteneur:"
    podman logs go-app-test
    EXIT_CODE=1
fi

podman stop go-app-test
podman rm go-app-test
podman rmi go-app-test

exit $EXIT_CODE
