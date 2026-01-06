#!/bin/bash
echo "Test Python App"

podman build -t python-app-test .
podman run -d --name python-app-test -p 5001:5000 python-app-test
sleep 3

EXIT_CODE=0
if curl -s http://localhost:5001/api/health | grep -q "healthy"; then
    echo "[OK] Python app fonctionne"
else
    echo "[ERREUR] Python app ne repond pas"
    EXIT_CODE=1
fi

podman stop python-app-test
podman rm python-app-test
podman rmi python-app-test

exit $EXIT_CODE
