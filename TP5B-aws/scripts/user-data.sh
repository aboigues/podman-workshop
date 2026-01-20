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

# Configurer le socket Podman pour l'utilisateur ec2-user
echo "Configuration du socket Podman..."
systemctl enable --now podman.socket

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
