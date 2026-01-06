#!/bin/bash

echo "Test des capabilities"

EXIT_CODE=0

echo "1. Sans capabilities:"
if podman run --rm --cap-drop=ALL alpine sh -c "ping -c 1 8.8.8.8" 2>&1; then
    echo "[WARN] Ping reussi alors qu'il devrait etre bloque"
else
    echo "[OK] Ping correctement bloque sans capabilities"
fi

echo ""
echo "2. Avec CAP_NET_RAW:"
if podman run --rm --cap-drop=ALL --cap-add=NET_RAW alpine sh -c "ping -c 1 8.8.8.8" 2>&1; then
    echo "[OK] Ping autorise avec CAP_NET_RAW"
else
    echo "[ERREUR] Ping bloque malgre CAP_NET_RAW"
    EXIT_CODE=1
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "[OK] Tests passes"
else
    echo "[ERREUR] Tests echoues"
fi

exit $EXIT_CODE
