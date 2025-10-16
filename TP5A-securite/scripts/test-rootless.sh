#!/bin/bash

echo "Test mode rootless"

echo "1. Utilisateur dans le conteneur:"
podman run --rm alpine id

echo ""
echo "2. Mapping utilisateur:"
podman unshare cat /proc/self/uid_map
podman unshare cat /proc/self/gid_map

echo ""
echo "3. Verifier rootless:"
if podman system info | grep -q "runAsUser: [1-9]"; then
    echo "[OK] Mode rootless actif"
else
    echo "[WARN] Mode root detecte"
fi
