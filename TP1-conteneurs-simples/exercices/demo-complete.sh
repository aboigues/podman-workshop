#!/bin/bash

echo "=== TP1 - Demonstration complete ==="
echo ""

echo "Exercice 1: Lancement"
podman run -d --name demo-nginx -p 8080:80 nginx:alpine
sleep 2
echo "[OK] Conteneur lance"
curl -s http://localhost:8080 | head -n 5
echo ""

echo "Exercice 2: Logs"
podman logs demo-nginx | tail -n 5
echo "[OK] Logs affiches"
echo ""

echo "Exercice 3: Cycle de vie"
podman stop demo-nginx
echo "[OK] Conteneur arrete"
podman start demo-nginx
echo "[OK] Conteneur redemarre"
echo ""

echo "Exercice 4: Inspection"
echo "ID: $(podman inspect demo-nginx --format '{{.Id}}' | cut -c1-12)"
echo "IP: $(podman inspect demo-nginx --format '{{.NetworkSettings.IPAddress}}')"
echo "[OK] Inspection reussie"
echo ""

echo "Exercice 5: Commandes"
podman exec demo-nginx ls -la /usr/share/nginx/html/
echo "[OK] Commande executee"
echo ""

echo "Nettoyage..."
podman stop demo-nginx
podman rm demo-nginx
echo ""

echo "[OK] TP1 termine avec succes"
