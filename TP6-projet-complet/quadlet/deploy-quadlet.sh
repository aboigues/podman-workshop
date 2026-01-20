#!/bin/bash
# Script de déploiement TaskPlatform avec Quadlet
# Usage: ./deploy-quadlet.sh [install|start|stop|status|uninstall]

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
QUADLET_DIR="$HOME/.config/containers/systemd"
CONFIG_DIR="$HOME/.config/containers"
DATA_DIR="$HOME/taskplatform"

# Services dans l'ordre de démarrage
SERVICES=(postgres redis backend frontend nginx prometheus grafana)

# Fichiers Quadlet
NETWORKS=(taskplatform-backend taskplatform-frontend taskplatform-monitoring)
VOLUMES=(postgres-data redis-data prometheus-data grafana-data)
CONTAINERS=(postgres redis backend frontend nginx prometheus grafana)

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

check_prerequisites() {
    print_header "Vérification des prérequis"

    # Podman
    if ! command -v podman &> /dev/null; then
        print_error "Podman n'est pas installé"
        exit 1
    fi
    PODMAN_VERSION=$(podman --version | grep -oP '\d+\.\d+')
    print_success "Podman $PODMAN_VERSION installé"

    # Vérifier version >= 4.4
    if [[ $(echo "$PODMAN_VERSION < 4.4" | bc -l) -eq 1 ]]; then
        print_error "Podman 4.4+ requis pour Quadlet (version actuelle: $PODMAN_VERSION)"
        exit 1
    fi

    # systemd user
    if ! systemctl --user status &> /dev/null; then
        print_error "systemd user mode non disponible"
        exit 1
    fi
    print_success "systemd user mode disponible"

    # Quadlet
    if [ -x /usr/libexec/podman/quadlet ]; then
        print_success "Quadlet disponible"
    else
        print_error "Quadlet non trouvé"
        exit 1
    fi
}

build_images() {
    print_header "Construction des images"

    echo "Construction de backend..."
    podman build -t localhost/taskplatform-backend:latest "$PROJECT_DIR/app/backend"
    print_success "Image backend construite"

    echo "Construction de frontend..."
    podman build -t localhost/taskplatform-frontend:latest "$PROJECT_DIR/app/frontend"
    print_success "Image frontend construite"

    echo "Construction de nginx..."
    podman build -t localhost/taskplatform-nginx:latest "$PROJECT_DIR/nginx"
    print_success "Image nginx construite"
}

setup_config() {
    print_header "Configuration de l'environnement"

    # Créer les répertoires
    mkdir -p "$QUADLET_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DATA_DIR"

    # Copier les fichiers de config
    if [ ! -d "$DATA_DIR/monitoring" ]; then
        cp -r "$PROJECT_DIR/monitoring" "$DATA_DIR/"
        print_success "Fichiers monitoring copiés"
    fi

    if [ ! -d "$DATA_DIR/nginx" ]; then
        cp -r "$PROJECT_DIR/nginx" "$DATA_DIR/"
        print_success "Fichiers nginx copiés"
    fi

    # Créer le fichier d'environnement s'il n'existe pas
    if [ ! -f "$CONFIG_DIR/taskplatform.env" ]; then
        cat > "$CONFIG_DIR/taskplatform.env" << 'EOF'
# PostgreSQL
POSTGRES_DB=taskplatform
POSTGRES_USER=taskplatform
POSTGRES_PASSWORD=changeme_postgres_password

# Redis
REDIS_PASSWORD=changeme_redis_password

# Backend
DB_NAME=taskplatform
DB_USER=taskplatform
DB_PASSWORD=changeme_postgres_password
JWT_SECRET=changeme_jwt_secret_at_least_32_characters_long
JWT_EXPIRES_IN=7d

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=changeme_grafana_password
GF_SERVER_ROOT_URL=http://localhost:3001
EOF
        chmod 600 "$CONFIG_DIR/taskplatform.env"
        print_warning "Fichier taskplatform.env créé avec valeurs par défaut"
        print_warning "IMPORTANT: Modifiez les mots de passe dans $CONFIG_DIR/taskplatform.env"
    else
        print_success "Fichier taskplatform.env existe"
    fi
}

install_quadlets() {
    print_header "Installation des fichiers Quadlet"

    # Copier les networks
    for net in "${NETWORKS[@]}"; do
        cp "$SCRIPT_DIR/$net.network" "$QUADLET_DIR/"
        print_success "Network $net.network installé"
    done

    # Copier les volumes
    for vol in "${VOLUMES[@]}"; do
        cp "$SCRIPT_DIR/$vol.volume" "$QUADLET_DIR/"
        print_success "Volume $vol.volume installé"
    done

    # Copier les containers
    for container in "${CONTAINERS[@]}"; do
        cp "$SCRIPT_DIR/$container.container" "$QUADLET_DIR/"
        print_success "Container $container.container installé"
    done

    # Recharger systemd
    systemctl --user daemon-reload
    print_success "systemd rechargé"
}

start_services() {
    print_header "Démarrage des services"

    for service in "${SERVICES[@]}"; do
        echo "Démarrage de $service..."
        systemctl --user enable --now "$service" 2>/dev/null || true
        sleep 2
    done

    print_success "Tous les services démarrés"
    echo ""
    echo "Accès aux services:"
    echo "  - Application: http://localhost:80"
    echo "  - API: http://localhost:80/api"
    echo "  - Prometheus: http://localhost:9090"
    echo "  - Grafana: http://localhost:3001"
}

stop_services() {
    print_header "Arrêt des services"

    # Arrêter dans l'ordre inverse
    for ((i=${#SERVICES[@]}-1; i>=0; i--)); do
        service="${SERVICES[$i]}"
        echo "Arrêt de $service..."
        systemctl --user stop "$service" 2>/dev/null || true
    done

    print_success "Tous les services arrêtés"
}

show_status() {
    print_header "Statut des services"

    for service in "${SERVICES[@]}"; do
        status=$(systemctl --user is-active "$service" 2>/dev/null || echo "inactive")
        if [ "$status" == "active" ]; then
            echo -e "${GREEN}●${NC} $service: $status"
        else
            echo -e "${RED}●${NC} $service: $status"
        fi
    done

    echo ""
    echo "Conteneurs Podman:"
    podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep taskplatform || echo "Aucun conteneur taskplatform"
}

uninstall() {
    print_header "Désinstallation"

    # Arrêter les services
    stop_services

    # Désactiver les services
    for service in "${SERVICES[@]}"; do
        systemctl --user disable "$service" 2>/dev/null || true
    done

    # Supprimer les fichiers Quadlet
    for net in "${NETWORKS[@]}"; do
        rm -f "$QUADLET_DIR/$net.network"
    done
    for vol in "${VOLUMES[@]}"; do
        rm -f "$QUADLET_DIR/$vol.volume"
    done
    for container in "${CONTAINERS[@]}"; do
        rm -f "$QUADLET_DIR/$container.container"
    done

    # Recharger systemd
    systemctl --user daemon-reload
    systemctl --user reset-failed

    print_success "Fichiers Quadlet supprimés"

    echo ""
    print_warning "Les volumes et images n'ont pas été supprimés."
    echo "Pour une suppression complète:"
    echo "  podman volume rm taskplatform-postgres-data taskplatform-redis-data taskplatform-prometheus-data taskplatform-grafana-data"
    echo "  podman network rm taskplatform-backend taskplatform-frontend taskplatform-monitoring"
    echo "  podman rmi localhost/taskplatform-backend localhost/taskplatform-frontend localhost/taskplatform-nginx"
}

show_help() {
    echo "Usage: $0 [commande]"
    echo ""
    echo "Commandes:"
    echo "  install    - Installe et démarre tous les services"
    echo "  start      - Démarre les services"
    echo "  stop       - Arrête les services"
    echo "  restart    - Redémarre les services"
    echo "  status     - Affiche le statut des services"
    echo "  logs       - Affiche les logs (ajouter le nom du service)"
    echo "  uninstall  - Désinstalle les services"
    echo "  help       - Affiche cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 install"
    echo "  $0 status"
    echo "  $0 logs backend"
}

# Main
case "${1:-help}" in
    install)
        check_prerequisites
        build_images
        setup_config
        install_quadlets
        start_services
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services
        ;;
    status)
        show_status
        ;;
    logs)
        if [ -n "$2" ]; then
            journalctl --user -u "$2" -f
        else
            echo "Usage: $0 logs <service>"
            echo "Services: ${SERVICES[*]}"
        fi
        ;;
    uninstall)
        uninstall
        ;;
    help|*)
        show_help
        ;;
esac
