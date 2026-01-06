#!/bin/bash
#
# Test automatisé pour TP6 - Projet Complet
# Vérifie que la stack peut être construite et démarrée
#

set -e

echo "======================================"
echo "  Test TP6 - Projet Complet"
echo "======================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERREUR]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

FAILED=0

# Nettoyage initial
info "Nettoyage initial..."
podman-compose down -v 2>/dev/null || true
podman system prune -af --volumes 2>/dev/null || true

# Créer le fichier .env pour les tests
info "Création du fichier .env de test..."
cat > .env <<EOF
# Configuration de test pour TP6
POSTGRES_USER=taskuser
POSTGRES_PASSWORD=testpass123
POSTGRES_DB=taskplatform

REDIS_PASSWORD=redistest123

JWT_SECRET=test-jwt-secret-key-do-not-use-in-production

NODE_ENV=development

GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=grafanatest123
EOF

info "✓ Fichier .env créé"

# Créer les répertoires nécessaires
info "Création des répertoires..."
mkdir -p nginx/ssl
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/datasources

# Générer des certificats SSL auto-signés simples pour les tests
if command -v openssl &> /dev/null; then
    info "Génération des certificats SSL de test..."
    openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=FR/ST=Test/L=Test/O=Test/CN=localhost" \
        2>/dev/null || warning "Échec génération SSL (non bloquant)"
else
    warning "OpenSSL non disponible, création de fichiers vides..."
    touch nginx/ssl/key.pem nginx/ssl/cert.pem
fi

# Build des images
info "Construction des images..."
if ! podman-compose build --parallel 2>&1 | grep -v "WARN"; then
    error "Échec du build des images"
    ((FAILED++))
else
    info "✓ Images construites avec succès"
fi

# Démarrer la stack (sans les secrets Podman pour CI)
info "Démarrage de la stack..."
if ! podman-compose up -d; then
    error "Échec du démarrage de la stack"
    ((FAILED++))
else
    info "✓ Stack démarrée"
fi

# Attendre que les services démarrent
info "Attente du démarrage des services (30s)..."
sleep 30

# Vérifier que les conteneurs tournent
info "Vérification des conteneurs..."

EXPECTED_CONTAINERS=(
    "taskplatform-db"
    "taskplatform-redis"
    "taskplatform-backend"
    "taskplatform-frontend"
    "taskplatform-nginx"
    "taskplatform-prometheus"
    "taskplatform-grafana"
)

for container in "${EXPECTED_CONTAINERS[@]}"; do
    if podman ps --format "{{.Names}}" | grep -q "$container"; then
        info "✓ $container est en cours d'exécution"
    else
        error "✗ $container n'est pas en cours d'exécution"
        ((FAILED++))
    fi
done

# Tests de connectivité basiques
info "Tests de connectivité..."

# Test PostgreSQL (port 5432)
if podman exec taskplatform-db pg_isready -U taskuser &>/dev/null; then
    info "✓ PostgreSQL est prêt"
else
    warning "PostgreSQL n'est pas encore prêt (peut prendre plus de temps)"
fi

# Test Redis (port 6379)
if podman exec taskplatform-redis redis-cli ping &>/dev/null; then
    info "✓ Redis répond"
else
    warning "Redis ne répond pas encore"
fi

# Test Backend API (attendre qu'il démarre)
info "Attente du démarrage de l'API backend (10s supplémentaires)..."
sleep 10

if curl -sf http://localhost:4000/api/health &>/dev/null; then
    info "✓ Backend API répond"
elif podman logs taskplatform-backend | grep -q "Server listening"; then
    info "✓ Backend API a démarré (logs confirment)"
else
    warning "Backend API ne répond pas encore (peut nécessiter plus de temps)"
fi

# Test Frontend (port 3000 interne, pas exposé directement)
if podman ps --filter "name=taskplatform-frontend" --format "{{.Status}}" | grep -q "Up"; then
    info "✓ Frontend est démarré"
else
    warning "Frontend non démarré"
fi

# Test Nginx (port 80)
if curl -sf http://localhost/ &>/dev/null || curl -sf http://localhost &>/dev/null; then
    info "✓ Nginx répond"
else
    warning "Nginx ne répond pas encore"
fi

# Test Prometheus (port 9090)
if curl -sf http://localhost:9090/-/healthy &>/dev/null; then
    info "✓ Prometheus répond"
else
    warning "Prometheus ne répond pas encore"
fi

# Test Grafana (port 3001)
if curl -sf http://localhost:3001/api/health &>/dev/null; then
    info "✓ Grafana répond"
else
    warning "Grafana ne répond pas encore"
fi

# Afficher les logs en cas d'erreur
if [ $FAILED -gt 0 ]; then
    error "Des erreurs ont été détectées, affichage des logs..."
    echo ""
    echo "=== Logs PostgreSQL ==="
    podman logs taskplatform-db 2>&1 | tail -20
    echo ""
    echo "=== Logs Backend ==="
    podman logs taskplatform-backend 2>&1 | tail -20
    echo ""
    echo "=== Logs Frontend ==="
    podman logs taskplatform-frontend 2>&1 | tail -20
fi

# Nettoyage
info "Nettoyage de la stack..."
podman-compose down -v || true

# Nettoyer le fichier .env
rm -f .env

echo ""
if [ $FAILED -eq 0 ]; then
    echo "======================================"
    echo "  ✓ Test TP6 réussi!"
    echo "======================================"
    exit 0
else
    echo "======================================"
    echo "  ✗ Test TP6 échoué: $FAILED erreur(s)"
    echo "======================================"
    exit 1
fi
