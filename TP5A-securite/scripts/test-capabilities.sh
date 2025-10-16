#!/bin/bash

echo "Test des capabilities"

echo "1. Sans capabilities:"
podman run --rm --cap-drop=ALL alpine sh -c "ping -c 1 google.com" 2>&1 || echo "[BLOQUE] Ping bloque"

echo ""
echo "2. Avec CAP_NET_RAW:"
podman run --rm --cap-drop=ALL --cap-add=NET_RAW alpine sh -c "ping -c 1 google.com" && echo "[OK] Ping autorise"
