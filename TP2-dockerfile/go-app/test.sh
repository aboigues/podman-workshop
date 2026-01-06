#!/bin/bash
echo "Test Go App"

podman build -t go-app-test .
podman run -d --name go-app-test -p 8081:8080 go-app-test
sleep 3

EXIT_CODE=0
if curl -s http://localhost:8081/api/health | grep -q "healthy"; then
    echo "[OK] Go app fonctionne"
    SIZE=$(podman images go-app-test --format "{{.Size}}")
    echo "Taille image: $SIZE"
else
    echo "[ERREUR] Go app ne repond pas"
    EXIT_CODE=1
fi

podman stop go-app-test
podman rm go-app-test
podman rmi go-app-test

exit $EXIT_CODE
