#!/bin/bash
#
# Script de déploiement pour TaskPlatform
# Lance la stack complète et vérifie que tout est opérationnel
#

set -e

echo "======================================"
echo "  TaskPlatform - Déploiement"
echo "======================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Vérifier que setup.sh a été exécuté
if [ ! -f .env ]; then
    error "Fichier .env manquant. Exécutez d'abord ./scripts/setup.sh"
    exit 1
fi

# Arrêter la stack si elle tourne
if podman-compose ps | grep -q "Up"; then
    info "Arrêt de la stack existante..."
    podman-compose down
fi

# Démarrer la stack
info "Démarrage de la stack complète..."
podman-compose up -d

# Attendre que les services soient prêts
info "Attente du démarrage des services..."
sleep 10

# Fonction pour vérifier un service
check_service() {
    local service_name=$1
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local status
        status=$(podman inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "unknown")
        if [ "$status" = "healthy" ]; then
            info "✓ $service_name est prêt"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done

    error "✗ $service_name n'est pas prêt après ${max_attempts} tentatives"
    return 1
}

# Vérifier chaque service
echo ""
info "Vérification des services..."

FAILED=0

check_service "taskplatform-db" || ((FAILED++))
check_service "taskplatform-redis" || ((FAILED++))
check_service "taskplatform-api" || ((FAILED++))
check_service "taskplatform-frontend" || ((FAILED++))
check_service "taskplatform-nginx" || ((FAILED++))
check_service "taskplatform-prometheus" || ((FAILED++))
check_service "taskplatform-grafana" || ((FAILED++))

echo ""

if [ $FAILED -eq 0 ]; then
    echo "======================================"
    echo "  Déploiement réussi! ✓"
    echo "======================================"
    echo ""
    echo "La stack TaskPlatform est opérationnelle:"
    echo ""
    echo "  🌐 Application: http://localhost:8080"
    echo "  🔌 API: http://localhost:8080/api"
    echo "  📊 Grafana: http://localhost:3001"
    echo "  📈 Prometheus: http://localhost:9090"
    echo ""
    echo "Commandes utiles:"
    echo "  podman-compose ps          # Statut des services"
    echo "  podman-compose logs -f     # Logs en temps réel"
    echo "  podman-compose down        # Arrêter la stack"
    echo "  ./scripts/backup.sh        # Sauvegarder la DB"
    echo ""
else
    error "Déploiement échoué: $FAILED service(s) en erreur"
    echo ""
    echo "Consultez les logs:"
    echo "  podman-compose logs"
    exit 1
fi
