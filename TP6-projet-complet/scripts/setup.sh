#!/bin/bash
#
# Script de setup initial pour TaskPlatform
# Configure l'environnement, génère les secrets, et prépare les services
#

set -e

echo "======================================"
echo "  TaskPlatform - Setup Initial"
echo "======================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les prérequis
info "Vérification des prérequis..."

if ! command -v podman &> /dev/null; then
    error "Podman n'est pas installé"
    exit 1
fi

if ! command -v podman-compose &> /dev/null; then
    warning "podman-compose n'est pas installé"
    echo "Installation: pip3 install podman-compose"
    exit 1
fi

info "✓ Prérequis validés"

# Copier .env si nécessaire
if [ ! -f .env ]; then
    info "Création du fichier .env depuis .env.example..."
    cp .env.example .env
    warning "IMPORTANT: Éditez .env et changez les mots de passe!"
    echo ""
    read -p "Voulez-vous éditer .env maintenant? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} .env
    fi
fi

# Générer les secrets Podman
info "Génération des secrets Podman..."

generate_secret() {
    local secret_name=$1
    local secret_value=$2

    if podman secret inspect "$secret_name" &>/dev/null; then
        warning "Secret '$secret_name' existe déjà, on le garde"
    else
        echo "$secret_value" | podman secret create "$secret_name" -
        info "✓ Secret '$secret_name' créé"
    fi
}

# Charger les variables d'environnement
source .env

generate_secret "db_password" "$POSTGRES_PASSWORD"
generate_secret "redis_password" "$REDIS_PASSWORD"
generate_secret "jwt_secret" "$JWT_SECRET"
generate_secret "grafana_password" "$GF_SECURITY_ADMIN_PASSWORD"

# Créer les répertoires nécessaires
info "Création des répertoires..."
mkdir -p nginx/ssl
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/datasources

# Générer les certificats SSL auto-signés (dev)
if [ ! -f nginx/ssl/cert.pem ]; then
    info "Génération des certificats SSL auto-signés..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=FR/ST=IDF/L=Paris/O=TaskPlatform/CN=localhost" \
        2>/dev/null
    info "✓ Certificats SSL générés"
fi

# Build des images
info "Build des images Docker..."
podman-compose build --parallel

info "✓ Images construites"

echo ""
echo "======================================"
echo "  Setup terminé avec succès!"
echo "======================================"
echo ""
echo "Prochaines étapes:"
echo "  1. Vérifiez votre configuration: cat .env"
echo "  2. Démarrez la stack: podman-compose up -d"
echo "  3. Vérifiez les logs: podman-compose logs -f"
echo "  4. Accédez à l'application: http://localhost"
echo ""
echo "Interfaces:"
echo "  - Application: http://localhost"
echo "  - API: http://localhost/api"
echo "  - Grafana: http://localhost:3001 (admin/${GF_SECURITY_ADMIN_PASSWORD})"
echo "  - Prometheus: http://localhost:9090"
echo ""
