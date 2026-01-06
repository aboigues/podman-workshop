#!/bin/bash
# Solution Exercice 1

podman run -d --name mon-nginx -p 8080:80 nginx:latest
podman ps
curl http://localhost:8080
echo "[OK] Exercice 1 complete"
