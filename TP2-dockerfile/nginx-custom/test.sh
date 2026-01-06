#!/bin/bash
echo "Test Nginx Custom"

podman build -t nginx-custom-test .
podman run -d --name nginx-custom-test -p 8083:80 nginx-custom-test
sleep 2

EXIT_CODE=0
if curl -s http://localhost:8083/health | grep -q "healthy"; then
    echo "[OK] Nginx custom fonctionne"
else
    echo "[ERREUR] Nginx custom ne repond pas"
    EXIT_CODE=1
fi

podman stop nginx-custom-test
podman rm nginx-custom-test
podman rmi nginx-custom-test

exit $EXIT_CODE
