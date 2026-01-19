# Instructions TP4 - Quadlet

## Exercice 1 : Service simple avec Quadlet

```bash
# Créer le répertoire Quadlet
mkdir -p ~/.config/containers/systemd

# Créer le fichier Quadlet
cat > ~/.config/containers/systemd/nginx-service.container << 'EOF'
[Unit]
Description=Nginx Web Server

[Container]
ContainerName=nginx-service
Image=docker.io/library/nginx:alpine
PublishPort=8080:80

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Activer le service
systemctl --user daemon-reload
systemctl --user enable --now nginx-service

# Vérifier
systemctl --user status nginx-service
curl http://localhost:8080
```

## Exercice 2 : Service avec volume

```bash
# Créer le contenu web
mkdir -p ~/webapp-data
echo "<h1>Hello Quadlet!</h1>" > ~/webapp-data/index.html

# Créer le fichier Quadlet avec volume
cat > ~/.config/containers/systemd/webapp-service.container << 'EOF'
[Unit]
Description=Web App with Volume

[Container]
ContainerName=webapp-service
Image=docker.io/library/nginx:alpine
PublishPort=8081:80
Volume=%h/webapp-data:/usr/share/nginx/html:ro,Z

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Activer
systemctl --user daemon-reload
systemctl --user enable --now webapp-service

# Tester
curl http://localhost:8081
```

## Exercice 3 : Pod avec Quadlet

```bash
# Créer le fichier Pod
cat > ~/.config/containers/systemd/webapp-pod.pod << 'EOF'
[Pod]
PodName=webapp-pod
PublishPort=8082:80

[Install]
WantedBy=default.target
EOF

# Créer le conteneur web
cat > ~/.config/containers/systemd/webapp-web.container << 'EOF'
[Unit]
Description=Web Frontend
After=webapp-pod-pod.service
BindsTo=webapp-pod-pod.service

[Container]
ContainerName=webapp-web
Image=docker.io/library/nginx:alpine
Pod=webapp-pod.pod

[Install]
WantedBy=default.target
EOF

# Créer le conteneur Redis
cat > ~/.config/containers/systemd/webapp-redis.container << 'EOF'
[Unit]
Description=Redis Cache
After=webapp-pod-pod.service
BindsTo=webapp-pod-pod.service

[Container]
ContainerName=webapp-redis
Image=docker.io/library/redis:7-alpine
Pod=webapp-pod.pod

[Install]
WantedBy=default.target
EOF

# Activer le pod (les conteneurs démarrent automatiquement)
systemctl --user daemon-reload
systemctl --user enable --now webapp-pod-pod

# Vérifier
systemctl --user status webapp-pod-pod
podman pod ps
podman ps --pod
```

## Commandes utiles

```bash
# Voir les logs
journalctl --user -u nginx-service -f

# Redémarrer un service
systemctl --user restart nginx-service

# Arrêter un service
systemctl --user stop nginx-service

# Désactiver un service
systemctl --user disable nginx-service

# Voir l'unité générée par Quadlet
systemctl --user cat nginx-service

# Vérifier la syntaxe des fichiers Quadlet
/usr/libexec/podman/quadlet -dryrun -user
```

## Nettoyage

```bash
# Arrêter et supprimer tous les services
systemctl --user stop nginx-service webapp-service webapp-pod-pod
systemctl --user disable nginx-service webapp-service webapp-pod-pod

# Supprimer les fichiers Quadlet
rm ~/.config/containers/systemd/*.container
rm ~/.config/containers/systemd/*.pod

# Recharger systemd
systemctl --user daemon-reload
systemctl --user reset-failed

# Nettoyer les conteneurs orphelins
podman rm -af
podman pod rm -af
```
