#!/bin/bash
# User-data script pour déployer TaskPlatform sur Amazon Linux 2023
# Ce script est exécuté par cloud-init au premier démarrage de l'instance

set -e

# Logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Début user-data: $(date) ==="

# Variables (injectées par Terraform)
GIT_REPO="${git_repo}"
INSTALL_DIR="/opt/taskplatform"

# Mettre à jour le système
echo "Mise à jour du système..."
dnf update -y

# Installer Podman et outils
echo "Installation de Podman et dépendances..."
dnf install -y podman podman-compose git curl jq

# Vérifier l'installation
echo "Version Podman: $(podman --version)"

# Configurer Podman pour l'utilisateur ec2-user (rootless)
echo "Configuration de Podman rootless pour ec2-user..."

# Permettre aux utilisateurs non-root de binder sur les ports >= 80
echo "net.ipv4.ip_unprivileged_port_start=80" >> /etc/sysctl.d/99-podman.conf
sysctl -w net.ipv4.ip_unprivileged_port_start=80

# Activer le linger pour que les conteneurs persistent après déconnexion
loginctl enable-linger ec2-user

# Cloner le repository
echo "Clonage du repository..."
git clone "$GIT_REPO" "$INSTALL_DIR"
chown -R ec2-user:ec2-user "$INSTALL_DIR"

# Créer le fichier .env
echo "Configuration de l'environnement..."
cd "$INSTALL_DIR/TP6-projet-complet"

# Générer des mots de passe sécurisés
DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
JWT_SECRET=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c 64)
GRAFANA_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)

cat > .env << EOF
# Configuration générée automatiquement par Terraform
# Date: $(date)

# Database
POSTGRES_DB=taskdb
POSTGRES_USER=taskuser
POSTGRES_PASSWORD=$DB_PASSWORD
DB_HOST=postgres
DB_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD

# Backend API
NODE_ENV=production
API_PORT=4000
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d

# Frontend
REACT_APP_API_URL=http://localhost:8080/api

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PASSWORD
GF_SERVER_ROOT_URL=http://localhost:3001

# Prometheus
PROMETHEUS_RETENTION=15d

# Nginx
NGINX_HOST=localhost
NGINX_PORT=8080
NGINX_SSL_PORT=443
EOF

chown ec2-user:ec2-user .env
chmod 600 .env

# Sauvegarder le mot de passe Grafana pour l'utilisateur
echo "Grafana admin password: $GRAFANA_PASSWORD" > /home/ec2-user/grafana-credentials.txt
chown ec2-user:ec2-user /home/ec2-user/grafana-credentials.txt
chmod 600 /home/ec2-user/grafana-credentials.txt

# Déployer la stack en tant que ec2-user
echo "Déploiement de la stack TaskPlatform..."
sudo -u ec2-user bash -c "
    cd $INSTALL_DIR/TP6-projet-complet
    export XDG_RUNTIME_DIR=/run/user/\$(id -u)

    # Build des images
    echo 'Build des images...'
    podman-compose build

    # Démarrage de la stack
    echo 'Démarrage de la stack...'
    podman-compose up -d

    # Attendre que les services soient prêts
    echo 'Attente du démarrage des services...'
    sleep 30

    # Vérifier l'état
    podman-compose ps
"

# Créer un script de gestion pour ec2-user
cat > /home/ec2-user/taskplatform.sh << 'EOF'
#!/bin/bash
# Script de gestion TaskPlatform

INSTALL_DIR="/opt/taskplatform/TP6-projet-complet"

case "$1" in
    status)
        cd "$INSTALL_DIR" && podman-compose ps
        ;;
    logs)
        cd "$INSTALL_DIR" && podman-compose logs -f ${2:-}
        ;;
    restart)
        cd "$INSTALL_DIR" && podman-compose restart
        ;;
    stop)
        cd "$INSTALL_DIR" && podman-compose down
        ;;
    start)
        cd "$INSTALL_DIR" && podman-compose up -d
        ;;
    health)
        echo "=== Health Checks ==="
        echo -n "API: "
        curl -s http://localhost:8080/api/health || echo "FAILED"
        echo ""
        echo -n "Prometheus: "
        curl -s http://localhost:9090/-/healthy || echo "FAILED"
        echo ""
        echo -n "Grafana: "
        curl -s http://localhost:3001/api/health || echo "FAILED"
        echo ""
        ;;
    *)
        echo "Usage: $0 {status|logs|restart|stop|start|health}"
        echo ""
        echo "Commands:"
        echo "  status  - Show container status"
        echo "  logs    - Follow logs (optionally specify service name)"
        echo "  restart - Restart all services"
        echo "  stop    - Stop all services"
        echo "  start   - Start all services"
        echo "  health  - Check health of all endpoints"
        exit 1
        ;;
esac
EOF

chmod +x /home/ec2-user/taskplatform.sh
chown ec2-user:ec2-user /home/ec2-user/taskplatform.sh

# Ajouter des alias utiles
cat >> /home/ec2-user/.bashrc << 'EOF'

# Alias TaskPlatform
alias tp='~/taskplatform.sh'
alias tplogs='~/taskplatform.sh logs'
alias tpstatus='~/taskplatform.sh status'
alias docker='podman'
alias dc='podman-compose'

# Message de bienvenue
echo "========================================"
echo "  TaskPlatform - Instance AWS"
echo "========================================"
echo ""
echo "Commandes utiles:"
echo "  tp status  - État des conteneurs"
echo "  tp health  - Vérifier les endpoints"
echo "  tp logs    - Voir les logs"
echo ""
echo "Accès aux services:"
echo "  Application: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "  Grafana:     http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001"
echo "  Prometheus:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo ""
echo "Credentials Grafana: cat ~/grafana-credentials.txt"
echo "========================================"
EOF

echo "=== Fin user-data: $(date) ==="
echo "Installation terminée avec succès" > /var/log/taskplatform-setup.log
