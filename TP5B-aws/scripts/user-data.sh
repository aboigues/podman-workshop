#!/bin/bash
# User-data script pour Amazon Linux 2023
# Ce script est exécuté par cloud-init au premier démarrage de l'instance

set -e

# Logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Début user-data: $(date) ==="

# Mettre à jour le système
echo "Mise à jour du système..."
dnf update -y

# Installer Podman et outils
echo "Installation de Podman..."
dnf install -y podman podman-compose git curl

# Vérifier l'installation
podman --version

# Configurer Podman pour l'utilisateur ec2-user (rootless)
echo "Configuration de Podman rootless pour ec2-user..."

# Permettre aux utilisateurs non-root de binder sur les ports >= 80
echo "net.ipv4.ip_unprivileged_port_start=80" >> /etc/sysctl.d/99-podman.conf
sysctl -w net.ipv4.ip_unprivileged_port_start=80

# Activer le linger pour que les conteneurs persistent après déconnexion
loginctl enable-linger ec2-user

# Activer le socket Podman au niveau utilisateur (pour l'API Docker-compatible)
sudo -u ec2-user XDG_RUNTIME_DIR="/run/user/$(id -u ec2-user)" systemctl --user enable podman.socket

# Créer un script de test pour ec2-user
cat > /home/ec2-user/test-podman.sh << 'EOF'
#!/bin/bash
echo "Test de Podman..."
podman run --rm hello-world
echo ""
echo "Lancement de nginx sur le port 80..."
podman run -d --name nginx-test -p 80:80 nginx:alpine
echo "Nginx lancé! Testez avec: curl http://localhost"
EOF

chmod +x /home/ec2-user/test-podman.sh
chown ec2-user:ec2-user /home/ec2-user/test-podman.sh

# Créer un alias pour faciliter l'utilisation
cat >> /home/ec2-user/.bashrc << 'EOF'

# Alias Podman
alias docker='podman'
alias dc='podman-compose'

# Message de bienvenue
echo "========================================"
echo "  Podman Workshop - Instance prête!"
echo "  Lancez ./test-podman.sh pour tester"
echo "========================================"
EOF

echo "=== Fin user-data: $(date) ==="
echo "Installation terminée avec succès" > /var/log/podman-setup.log
