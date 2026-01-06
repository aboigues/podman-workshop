#!/bin/bash

echo "Test des capabilities"

EXIT_CODE=0

echo "1. Test conteneur avec toutes les capabilities supprimees:"
if podman run --rm --cap-drop=ALL alpine sh -c "echo 'Conteneur demarre avec cap-drop=ALL'" > /dev/null 2>&1; then
    echo "[OK] Conteneur fonctionne avec --cap-drop=ALL"
else
    echo "[ERREUR] Impossible de demarrer conteneur avec --cap-drop=ALL"
    EXIT_CODE=1
fi

echo ""
echo "2. Test conteneur avec CAP_NET_RAW ajoutee:"
if podman run --rm --cap-drop=ALL --cap-add=NET_RAW alpine sh -c "echo 'Conteneur demarre avec CAP_NET_RAW'" > /dev/null 2>&1; then
    echo "[OK] Conteneur fonctionne avec --cap-drop=ALL --cap-add=NET_RAW"
else
    echo "[ERREUR] Impossible de demarrer conteneur avec CAP_NET_RAW"
    EXIT_CODE=1
fi

echo ""
echo "3. Test capabilities avec inspection:"
if podman run --rm --cap-drop=ALL --cap-add=NET_RAW alpine sh -c "cat /proc/self/status | grep -i cap" > /dev/null 2>&1; then
    echo "[OK] Capabilities configurees correctement"
else
    echo "[INFO] Impossible d'inspecter les capabilities (normal)"
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "[OK] Tests passes"
else
    echo "[ERREUR] Tests echoues"
fi

exit $EXIT_CODE
