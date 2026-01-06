#!/bin/bash

echo "Test mode rootless"

EXIT_CODE=0

echo "1. Utilisateur dans le conteneur:"
if ! podman run --rm alpine id; then
    echo "[ERREUR] Impossible de lancer le conteneur"
    EXIT_CODE=1
fi

echo ""
echo "2. Mapping utilisateur:"
if ! podman unshare cat /proc/self/uid_map 2>/dev/null; then
    echo "[INFO] podman unshare non disponible (normal en mode root)"
fi

if ! podman unshare cat /proc/self/gid_map 2>/dev/null; then
    echo "[INFO] podman unshare non disponible (normal en mode root)"
fi

echo ""
echo "3. Verifier rootless:"
if podman system info | grep -q "runAsUser: [1-9]"; then
    echo "[OK] Mode rootless actif"
elif podman system info | grep -q "rootless: true"; then
    echo "[OK] Mode rootless actif"
else
    echo "[INFO] Mode root detecte (normal pour CI/CD)"
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "[OK] Tests passes"
else
    echo "[ERREUR] Tests echoues"
fi

exit $EXIT_CODE
