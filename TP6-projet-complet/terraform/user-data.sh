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
EC2_USER="ec2-user"
EC2_UID=$(id -u $EC2_USER)

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
loginctl enable-linger $EC2_USER

# Créer le XDG_RUNTIME_DIR manuellement (nécessaire avant le premier login)
echo "Création du XDG_RUNTIME_DIR pour $EC2_USER..."
mkdir -p /run/user/$EC2_UID
chown $EC2_USER:$EC2_USER /run/user/$EC2_UID
chmod 700 /run/user/$EC2_UID

# Cloner le repository
echo "Clonage du repository..."
if ! git clone "$GIT_REPO" "$INSTALL_DIR"; then
    echo "ERREUR: Impossible de cloner le repository"
    exit 1
fi
chown -R $EC2_USER:$EC2_USER "$INSTALL_DIR"

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

chown $EC2_USER:$EC2_USER .env
chmod 600 .env

# Sauvegarder le mot de passe Grafana pour l'utilisateur
echo "Grafana admin password: $GRAFANA_PASSWORD" > /home/$EC2_USER/grafana-credentials.txt
chown $EC2_USER:$EC2_USER /home/$EC2_USER/grafana-credentials.txt
chmod 600 /home/$EC2_USER/grafana-credentials.txt

# Déployer la stack en tant que ec2-user
echo "Déploiement de la stack TaskPlatform..."
sudo -u $EC2_USER XDG_RUNTIME_DIR=/run/user/$EC2_UID bash -c '
    cd /opt/taskplatform/TP6-projet-complet

    # Build des images
    echo "Build des images..."
    if ! podman-compose build; then
        echo "ERREUR: Build des images échoué"
        exit 1
    fi

    # Démarrage de la stack
    echo "Démarrage de la stack..."
    if ! podman-compose up -d; then
        echo "ERREUR: Démarrage de la stack échoué"
        exit 1
    fi

    # Attendre que les services soient prêts
    echo "Attente du démarrage des services..."
    sleep 30

    # Vérifier létat
    podman-compose ps
'

# Vérifier que le déploiement a réussi
if [ $? -ne 0 ]; then
    echo "ERREUR: Déploiement de la stack échoué"
    exit 1
fi

# Créer un script de gestion pour l'utilisateur
cat > /home/$EC2_USER/taskplatform.sh << 'EOF'
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

chmod +x /home/$EC2_USER/taskplatform.sh
chown $EC2_USER:$EC2_USER /home/$EC2_USER/taskplatform.sh

# Récupérer l'IP publique et la stocker (évite les appels répétés au metadata service)
PUBLIC_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 || echo "IP_NON_DISPONIBLE")
echo "$PUBLIC_IP" > /home/$EC2_USER/.instance-public-ip
chown $EC2_USER:$EC2_USER /home/$EC2_USER/.instance-public-ip

# Ajouter des alias utiles
cat >> /home/$EC2_USER/.bashrc << 'EOF'

# Alias TaskPlatform
alias tp='~/taskplatform.sh'
alias tplogs='~/taskplatform.sh logs'
alias tpstatus='~/taskplatform.sh status'
alias docker='podman'
alias dc='podman-compose'

# Message de bienvenue
_show_welcome() {
    local PUBLIC_IP=$(cat ~/.instance-public-ip 2>/dev/null || echo "IP_NON_DISPONIBLE")
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
    echo "  Application: http://$PUBLIC_IP:8080"
    echo "  Grafana:     http://$PUBLIC_IP:3001"
    echo "  Prometheus:  http://$PUBLIC_IP:9090"
    echo ""
    echo "Credentials Grafana: cat ~/grafana-credentials.txt"
    echo "========================================"
}
_show_welcome
EOF

echo "=== Fin user-data: $(date) ==="
echo "Installation terminée avec succès" > /var/log/taskplatform-setup.log
