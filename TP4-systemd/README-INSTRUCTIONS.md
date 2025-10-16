# Instructions TP4

## Exercice 1 : Service simple

```bash
# Creer un conteneur
podman run -d --name nginx-service -p 8080:80 nginx:alpine

# Generer le service
podman generate systemd --new --files --name nginx-service

# Installer
mkdir -p ~/.config/systemd/user
mv container-nginx-service.service ~/.config/systemd/user/

# Activer
systemctl --user daemon-reload
systemctl --user enable container-nginx-service.service
systemctl --user start container-nginx-service.service

# Verifier
systemctl --user status container-nginx-service.service
```

## Exercice 2 : Service avec volume

```bash
# Creer avec volume
podman create --name webapp-service \
    -p 8080:80 \
    -v /opt/webapp:/usr/share/nginx/html:ro \
    nginx:alpine

# Generer et installer
podman generate systemd --new --files --name webapp-service
mv container-webapp-service.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now container-webapp-service.service
```

## Exercice 3 : Pod avec systemd

```bash
# Creer un pod
podman pod create --name webapp-pod -p 8080:80

# Ajouter des conteneurs
podman run -d --pod webapp-pod --name web nginx:alpine
podman run -d --pod webapp-pod --name redis redis:alpine

# Generer services
podman generate systemd --new --files --name webapp-pod

# Installer tous les services
mv pod-webapp-pod.service container-*.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now pod-webapp-pod.service
```
