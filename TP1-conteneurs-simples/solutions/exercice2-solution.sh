#!/bin/bash
# Solution Exercice 2

podman logs mon-nginx
podman logs --tail 10 mon-nginx
podman logs -t mon-nginx
echo "[OK] Exercice 2 complete"
