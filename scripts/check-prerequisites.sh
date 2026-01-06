#!/bin/bash

echo "Verification des prerequis"
echo "==========================="

ERRORS=0

check_command() {
    if command -v "$1" &> /dev/null; then
        VERSION=$("$1" --version 2>&1 | head -n1)
        echo "[OK] $1: $VERSION"
        return 0
    else
        echo "[ERREUR] $1: Non installe"
        return 1
    fi
}

echo "Outils obligatoires:"
check_command podman || ((ERRORS++))
check_command git || ((ERRORS++))

echo ""
echo "Outils optionnels:"
check_command podman-compose || echo "[INFO] podman-compose: Optionnel pour TP3"
check_command terraform || echo "[INFO] terraform: Optionnel pour TP5B"
check_command aws || echo "[INFO] aws-cli: Optionnel pour TP5B"

echo ""
echo "Systeme:"
echo "OS: $(uname -s)"
echo "Architecture: $(uname -m)"

if [ $ERRORS -eq 0 ]; then
    echo ""
    echo "[OK] Tous les prerequis sont satisfaits"
    exit 0
else
    echo ""
    echo "[ERREUR] $ERRORS prerequis manquants"
    exit 1
fi
