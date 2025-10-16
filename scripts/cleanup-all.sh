#!/bin/bash

echo "Nettoyage complet"
echo "================="

echo "Arret de tous les conteneurs..."
podman stop -a 2>/dev/null || true

echo "Suppression de tous les conteneurs..."
podman rm -a 2>/dev/null || true

echo "Suppression des images de test..."
podman rmi $(podman images --filter "reference=*-test" -q) 2>/dev/null || true

echo "Suppression des volumes non utilises..."
podman volume prune -f 2>/dev/null || true

echo "Suppression des reseaux non utilises..."
podman network prune -f 2>/dev/null || true

echo ""
echo "[OK] Nettoyage termine"
