# TP4 - Automatisation avec Systemd et Quadlet

## Objectifs
- Comprendre l'intégration entre Podman et systemd
- Automatiser le démarrage et l'arrêt des conteneurs au boot du système
- Gérer les conteneurs comme des services système natifs
- **Maîtriser Quadlet** : l'approche moderne et déclarative (Podman 4.4+)
- Implémenter des politiques de redémarrage automatique
- Gérer les dépendances entre services

## Prérequis
- Podman 4.4+ installé (vérifier avec `podman --version`)
- Systemd (présent sur la plupart des distributions Linux)
- Accès terminal
- Connaissances de base sur systemd

## Démarrage rapide avec Quadlet

```bash
# Créer le répertoire Quadlet utilisateur
mkdir -p ~/.config/containers/systemd

# Créer un fichier Quadlet pour nginx
cat > ~/.config/containers/systemd/nginx-demo.container << 'EOF'
[Container]
ContainerName=nginx-demo
Image=docker.io/library/nginx:alpine
PublishPort=8080:80

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Recharger systemd pour détecter le nouveau Quadlet
systemctl --user daemon-reload

# Démarrer le service (le nom est automatiquement généré)
systemctl --user start nginx-demo

# Vérifier le statut
systemctl --user status nginx-demo
```

---

## Introduction à systemd et Podman

**Systemd** est le système d'initialisation et de gestion de services par défaut sur la plupart des distributions Linux modernes. L'intégration de Podman avec systemd permet de :

### Avantages de l'intégration Podman + systemd

- **Démarrage automatique** : Les conteneurs démarrent automatiquement au boot du système
- **Gestion native** : Utilisation des commandes systemctl standard pour gérer les conteneurs
- **Redémarrage automatique** : Politique de redémarrage en cas d'échec
- **Logs centralisés** : Intégration avec journald pour une gestion unifiée des logs
- **Dépendances** : Gestion des dépendances entre services (réseau, base de données, etc.)
- **Rootless** : Support complet du mode sans privilèges avec systemd --user
- **Isolation** : Meilleure isolation et intégration avec les mécanismes de sécurité du système

### Modes d'exécution systemd

**Mode système (root)** : `systemctl`
- Services disponibles pour tous les utilisateurs
- Démarrage au boot du système
- Fichiers dans `/etc/systemd/system/` ou `/etc/containers/systemd/`
- Nécessite les privilèges root

**Mode utilisateur (rootless)** : `systemctl --user`
- Services propres à chaque utilisateur
- Démarrage à la connexion de l'utilisateur
- Fichiers dans `~/.config/systemd/user/` ou `~/.config/containers/systemd/`
- Ne nécessite pas les privilèges root
- **Recommandé avec Podman pour la sécurité**

---

## Quadlet : L'approche moderne (Podman 4.4+)

### Qu'est-ce que Quadlet ?

**Quadlet** est un générateur systemd intégré à Podman qui transforme des fichiers de configuration déclaratifs en unités systemd. C'est le successeur officiel de `podman generate systemd`.

#### Origine et philosophie

Quadlet a été introduit dans **Podman 4.4** (février 2023) pour résoudre les limitations de l'ancienne approche. Le nom "Quadlet" vient de la combinaison de "quad" (4, pour Podman 4) et "let" (petit fichier de configuration).

L'idée fondamentale est de **séparer la définition du conteneur de sa gestion systemd** :
- Vous décrivez **ce que vous voulez** (un conteneur nginx sur le port 8080)
- Quadlet génère **comment le faire** (les commandes ExecStart, ExecStop, etc.)

#### Comment fonctionne Quadlet ?

```
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  nginx.container    │────▶│  Générateur      │────▶│  nginx.service      │
│  (fichier déclaratif)│     │  Quadlet         │     │  (unité systemd)    │
└─────────────────────┘     └──────────────────┘     └─────────────────────┘
         Vous écrivez            Automatique            systemd utilise
```

1. **Vous créez** un fichier `.container` dans `~/.config/containers/systemd/`
2. **Vous exécutez** `systemctl --user daemon-reload`
3. **Quadlet détecte** le fichier et génère automatiquement l'unité systemd
4. **systemd gère** le service comme n'importe quel autre service

#### Avantages concrets

**1. Fichiers simples et lisibles**

Ancienne méthode (`podman generate systemd`) :
```ini
# Généré automatiquement - 20+ lignes complexes
[Service]
Type=notify
ExecStartPre=/usr/bin/podman rm -f nginx
ExecStart=/usr/bin/podman run --name nginx -p 8080:80 nginx:alpine
ExecStop=/usr/bin/podman stop nginx
ExecStopPost=/usr/bin/podman rm -f nginx
# ... beaucoup d'autres lignes
```

Nouvelle méthode (Quadlet) :
```ini
# Écrit par vous - simple et clair
[Container]
ContainerName=nginx
Image=docker.io/library/nginx:alpine
PublishPort=8080:80
```

**2. Mises à jour automatiques**

Avec l'ancienne méthode, si Podman corrigeait un bug dans la génération des services, vous deviez :
1. Arrêter le service
2. Supprimer le fichier
3. Régénérer avec `podman generate systemd`
4. Redémarrer

Avec Quadlet, un simple `daemon-reload` suffit pour bénéficier des améliorations.

**3. Cohérence avec l'écosystème**

La syntaxe Quadlet ressemble à :
- Docker Compose (approche déclarative)
- Kubernetes (fichiers de configuration)
- Fichiers INI standards (facile à apprendre)

### Pourquoi Quadlet remplace `podman generate systemd` ?

| Aspect | `podman generate systemd` (déprécié) | **Quadlet** (recommandé) |
|--------|--------------------------------------|--------------------------|
| Approche | Impérative (génère des fichiers) | Déclarative (fichiers de config) |
| Maintenance | Fichiers statiques à régénérer | Mises à jour automatiques |
| Simplicité | Commandes complexes | Syntaxe simple de type INI |
| Évolution | Figé à la génération | Bénéficie des améliorations Podman |
| Workflow | Similaire aux scripts | Similaire à Compose/Kubernetes |

> **Note importante** : `podman generate systemd` est officiellement **déprécié** depuis Podman 4.4.
> Il reste disponible pour la compatibilité mais ne recevra plus de nouvelles fonctionnalités.
> Voir la section [Migration depuis podman generate systemd](#migration-depuis-podman-generate-systemd) en fin de document.

### Emplacements des fichiers Quadlet

| Mode | Emplacement | Description |
|------|-------------|-------------|
| Utilisateur | `~/.config/containers/systemd/` | Services personnels (recommandé) |
| Utilisateur (alt) | `~/.config/systemd/user/` | Alternative |
| Système | `/etc/containers/systemd/` | Services système (root) |
| Système (alt) | `/usr/share/containers/systemd/` | Services système (paquets) |

### Types de fichiers Quadlet

| Extension | Description | Exemple |
|-----------|-------------|---------|
| `.container` | Définition d'un conteneur | `nginx.container` |
| `.pod` | Définition d'un pod | `webapp.pod` |
| `.volume` | Définition d'un volume | `data.volume` |
| `.network` | Définition d'un réseau | `backend.network` |
| `.image` | Construction d'image | `myapp.image` |
| `.kube` | Déploiement Kubernetes YAML | `deploy.kube` |

---

## Structure d'un fichier Quadlet .container

### Exemple de base

```ini
[Unit]
Description=Mon conteneur Nginx
After=network-online.target

[Container]
ContainerName=nginx-web
Image=docker.io/library/nginx:alpine
PublishPort=8080:80
Volume=/srv/www:/usr/share/nginx/html:ro,Z

[Service]
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

### Explications des sections

#### Section `[Unit]`

Identique aux unités systemd standard :

```ini
[Unit]
Description=Description du service
After=network-online.target      # Démarre après le réseau
Wants=network-online.target      # Dépendance souple
Requires=autre.service           # Dépendance forte
```

#### Section `[Container]`

Spécifique à Quadlet, définit le conteneur :

| Directive | Description | Exemple |
|-----------|-------------|---------|
| `ContainerName=` | Nom du conteneur | `ContainerName=nginx` |
| `Image=` | Image à utiliser (chemin complet recommandé) | `Image=docker.io/library/nginx:alpine` |
| `PublishPort=` | Publication de port | `PublishPort=8080:80` |
| `Volume=` | Montage de volume | `Volume=/data:/app/data:Z` |
| `Environment=` | Variable d'environnement | `Environment=DEBUG=true` |
| `EnvironmentFile=` | Fichier de variables | `EnvironmentFile=/etc/myapp.env` |
| `Network=` | Réseau à utiliser | `Network=backend.network` |
| `Pod=` | Pod parent | `Pod=webapp.pod` |
| `Exec=` | Commande à exécuter | `Exec=/bin/sh -c "echo hello"` |
| `User=` | Utilisateur dans le conteneur | `User=1000` |
| `Group=` | Groupe dans le conteneur | `Group=1000` |
| `Label=` | Labels du conteneur | `Label=app=web` |
| `Annotation=` | Annotations | `Annotation=description=Web server` |
| `AddCapability=` | Capacités à ajouter | `AddCapability=NET_ADMIN` |
| `DropCapability=` | Capacités à retirer | `DropCapability=ALL` |
| `SecurityLabelDisable=` | Désactive SELinux | `SecurityLabelDisable=true` |
| `ReadOnly=` | Système de fichiers en lecture seule | `ReadOnly=true` |
| `RunInit=` | Exécute un init (tini) | `RunInit=true` |
| `Notify=` | Active sd_notify | `Notify=true` |
| `AutoUpdate=` | Mise à jour automatique | `AutoUpdate=registry` |
| `PodmanArgs=` | Arguments Podman supplémentaires | `PodmanArgs=--memory=512m` |

#### Section `[Service]`

Configuration systemd du service :

```ini
[Service]
Restart=on-failure          # Politique de redémarrage
RestartSec=10               # Délai avant redémarrage
TimeoutStartSec=90          # Timeout de démarrage
TimeoutStopSec=30           # Timeout d'arrêt
```

#### Section `[Install]`

Définit quand le service démarre :

```ini
[Install]
WantedBy=default.target     # Mode utilisateur
# ou
WantedBy=multi-user.target  # Mode système
```

---

## Exercices pratiques avec Quadlet

### Exercice 1 : Service simple avec un conteneur

**Objectif** : Créer un service nginx géré par systemd via Quadlet.

```bash
# 1. Créer le répertoire Quadlet si nécessaire
mkdir -p ~/.config/containers/systemd

# 2. Créer le fichier Quadlet
cat > ~/.config/containers/systemd/nginx-service.container << 'EOF'
[Unit]
Description=Nginx Web Server
After=network-online.target

[Container]
ContainerName=nginx-service
Image=docker.io/library/nginx:alpine
PublishPort=8080:80

[Service]
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

# 3. Recharger systemd pour détecter le nouveau Quadlet
systemctl --user daemon-reload

# 4. Activer le service (démarrage automatique)
systemctl --user enable nginx-service

# 5. Démarrer le service
systemctl --user start nginx-service

# 6. Vérifier le statut
systemctl --user status nginx-service

# 7. Tester
curl http://localhost:8080
```

#### Explications détaillées

**Étape 2 : Création du fichier Quadlet**
- Le fichier `.container` décrit de manière déclarative le conteneur souhaité
- `Image=docker.io/library/nginx:alpine` : Chemin complet de l'image (recommandé)
- `PublishPort=8080:80` : Expose le port 80 du conteneur sur le port 8080 de l'hôte

**Étape 3 : daemon-reload**
- systemd scanne les répertoires Quadlet et génère automatiquement les unités
- Le nom du service est dérivé du nom du fichier (sans l'extension)

**Commandes utiles :**

```bash
# Voir les logs du service
journalctl --user -u nginx-service -f

# Redémarrer le service
systemctl --user restart nginx-service

# Arrêter le service
systemctl --user stop nginx-service

# Désactiver le démarrage automatique
systemctl --user disable nginx-service

# Voir l'unité systemd générée
systemctl --user cat nginx-service
```

---

### Exercice 2 : Service avec volume persistant

**Objectif** : Créer un service avec données persistantes.

```bash
# 1. Créer le fichier de volume Quadlet
cat > ~/.config/containers/systemd/webapp-data.volume << 'EOF'
[Volume]
# Options du volume
# Driver=local
# Label=app=webapp
EOF

# 2. Créer le répertoire pour le contenu local
mkdir -p ~/webapp-data
echo "<h1>Hello from Quadlet!</h1>" > ~/webapp-data/index.html

# 3. Créer le conteneur Quadlet avec volume
cat > ~/.config/containers/systemd/webapp-service.container << 'EOF'
[Unit]
Description=Web Application with Persistent Volume
After=network-online.target

[Container]
ContainerName=webapp-service
Image=docker.io/library/nginx:alpine
PublishPort=8081:80
# Volume local avec contexte SELinux
Volume=%h/webapp-data:/usr/share/nginx/html:ro,Z

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# 4. Recharger et démarrer
systemctl --user daemon-reload
systemctl --user enable --now webapp-service

# 5. Tester
curl http://localhost:8081
```

#### Explications détaillées

**Spécificateurs systemd dans Quadlet**
- `%h` : Répertoire home de l'utilisateur (`/home/username`)
- `%u` : Nom de l'utilisateur
- `%U` : UID de l'utilisateur
- `%t` : Répertoire runtime (`/run/user/UID`)

**Option `:Z` pour SELinux**
- Applique le contexte SELinux approprié au volume
- Nécessaire sur Fedora, RHEL, CentOS avec SELinux activé
- Alternative `:z` pour un contexte partagé entre conteneurs

---

### Exercice 3 : Pod avec plusieurs conteneurs

**Objectif** : Créer un pod avec une application web et un cache Redis.

```bash
# 1. Créer le fichier Pod Quadlet
cat > ~/.config/containers/systemd/webapp-pod.pod << 'EOF'
[Pod]
PodName=webapp-pod
PublishPort=8082:80

[Install]
WantedBy=default.target
EOF

# 2. Créer le conteneur web (appartient au pod)
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

# 3. Créer le conteneur Redis (appartient au pod)
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

# 4. Recharger et démarrer le pod
systemctl --user daemon-reload
systemctl --user enable --now webapp-pod-pod

# 5. Vérifier tous les services
systemctl --user status webapp-pod-pod
systemctl --user status webapp-web
systemctl --user status webapp-redis

# 6. Vérifier le pod Podman
podman pod ps
podman ps --pod
```

#### Explications détaillées

**Pods Podman**
- Un pod regroupe plusieurs conteneurs partageant les mêmes ressources réseau
- Tous les conteneurs du pod communiquent via `localhost`
- Le port est exposé au niveau du pod, pas des conteneurs individuels

**Nommage des services générés**
- Le fichier `webapp-pod.pod` génère le service `webapp-pod-pod.service`
- Le suffixe `-pod` est ajouté automatiquement

**Dépendances**
- `After=webapp-pod-pod.service` : Les conteneurs démarrent après le pod
- `BindsTo=webapp-pod-pod.service` : Les conteneurs s'arrêtent si le pod s'arrête

---

### Exercice 4 : Service avec réseau personnalisé

**Objectif** : Créer un réseau dédié pour isoler les conteneurs.

```bash
# 1. Créer le réseau Quadlet
cat > ~/.config/containers/systemd/backend.network << 'EOF'
[Network]
Subnet=10.89.0.0/24
Gateway=10.89.0.1
# Options avancées
# Driver=bridge
# DisableDNS=false
# Internal=false
EOF

# 2. Créer une base de données sur ce réseau
cat > ~/.config/containers/systemd/database.container << 'EOF'
[Unit]
Description=PostgreSQL Database

[Container]
ContainerName=database
Image=docker.io/library/postgres:15-alpine
Network=backend.network
# Variables d'environnement via fichier (sécurisé)
EnvironmentFile=%h/.config/containers/db.env
Volume=db-data:/var/lib/postgresql/data:Z

[Service]
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# 3. Créer le fichier d'environnement (sécurisé)
mkdir -p ~/.config/containers
cat > ~/.config/containers/db.env << 'EOF'
POSTGRES_PASSWORD=secure_password_here
POSTGRES_USER=webapp
POSTGRES_DB=myapp
EOF
chmod 600 ~/.config/containers/db.env

# 4. Créer une application utilisant la base de données
cat > ~/.config/containers/systemd/api-server.container << 'EOF'
[Unit]
Description=API Server
After=database.service
Requires=database.service

[Container]
ContainerName=api-server
Image=docker.io/library/python:3.12-slim
Network=backend.network
PublishPort=5000:5000
Environment=DATABASE_HOST=database
Environment=DATABASE_PORT=5432
Exec=python -m http.server 5000

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# 5. Déployer
systemctl --user daemon-reload
systemctl --user enable --now database api-server

# 6. Vérifier la connectivité
podman exec api-server ping -c 2 database
```

#### Note de sécurité

**Ne jamais mettre de secrets directement dans les fichiers Quadlet !**

Bonnes pratiques :
- Utiliser `EnvironmentFile=` avec un fichier protégé (`chmod 600`)
- Utiliser Podman secrets (`podman secret create`)
- Utiliser des gestionnaires de secrets externes

---

### Exercice 5 : Service avec mise à jour automatique

**Objectif** : Configurer un conteneur qui se met à jour automatiquement.

```bash
# 1. Créer le conteneur avec auto-update
cat > ~/.config/containers/systemd/auto-update-app.container << 'EOF'
[Unit]
Description=Auto-updating Application

[Container]
ContainerName=auto-update-app
Image=docker.io/library/nginx:alpine
PublishPort=8083:80
# Active la mise à jour automatique depuis le registre
AutoUpdate=registry
Label=io.containers.autoupdate=registry

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# 2. Démarrer
systemctl --user daemon-reload
systemctl --user enable --now auto-update-app

# 3. Activer le timer de mise à jour automatique
systemctl --user enable --now podman-auto-update.timer

# 4. Vérifier les mises à jour manuellement
podman auto-update --dry-run

# 5. Voir le timer
systemctl --user list-timers podman-auto-update.timer
```

#### Options AutoUpdate

| Valeur | Description |
|--------|-------------|
| `registry` | Vérifie et télécharge depuis le registre |
| `local` | Utilise l'image locale la plus récente |

---

## Commandes systemctl essentielles

### Gestion des services

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl --user start SERVICE` | Démarre un service | `systemctl --user start nginx-service` |
| `systemctl --user stop SERVICE` | Arrête un service | `systemctl --user stop nginx-service` |
| `systemctl --user restart SERVICE` | Redémarre un service | `systemctl --user restart nginx-service` |
| `systemctl --user enable SERVICE` | Active le démarrage automatique | `systemctl --user enable nginx-service` |
| `systemctl --user disable SERVICE` | Désactive le démarrage automatique | `systemctl --user disable nginx-service` |
| `systemctl --user enable --now SERVICE` | Active et démarre | `systemctl --user enable --now nginx-service` |

### Consultation

| Commande | Description |
|----------|-------------|
| `systemctl --user status SERVICE` | Affiche l'état d'un service |
| `systemctl --user list-units` | Liste tous les services actifs |
| `systemctl --user list-unit-files` | Liste tous les fichiers unit |
| `systemctl --user cat SERVICE` | Affiche le contenu de l'unité générée |
| `systemctl --user is-active SERVICE` | Vérifie si un service est actif |
| `systemctl --user is-enabled SERVICE` | Vérifie si un service est activé |

### Logs avec journalctl

| Commande | Description |
|----------|-------------|
| `journalctl --user -u SERVICE` | Affiche les logs d'un service |
| `journalctl --user -u SERVICE -f` | Logs en temps réel |
| `journalctl --user -u SERVICE --since today` | Logs depuis aujourd'hui |
| `journalctl --user -u SERVICE -n 50` | 50 dernières lignes |

### Gestion de systemd

| Commande | Description |
|----------|-------------|
| `systemctl --user daemon-reload` | **Indispensable** après modification d'un fichier Quadlet |
| `systemctl --user reset-failed` | Réinitialise l'état "failed" |
| `systemctl --user show SERVICE` | Affiche toutes les propriétés |

---

## Exemples avancés avec Quadlet

### Exemple 1 : Conteneur avec limites de ressources

```ini
# ~/.config/containers/systemd/limited-app.container
[Unit]
Description=Application avec limites de ressources

[Container]
ContainerName=limited-app
Image=docker.io/library/nginx:alpine
PublishPort=8084:80
# Limites via PodmanArgs
PodmanArgs=--memory=256m --cpus=0.5 --pids-limit=50

[Service]
Restart=on-failure
# Limites systemd additionnelles
MemoryMax=256M
CPUQuota=50%

[Install]
WantedBy=default.target
```

### Exemple 2 : Conteneur sécurisé (rootless + capabilities minimales)

```ini
# ~/.config/containers/systemd/secure-app.container
[Unit]
Description=Application sécurisée

[Container]
ContainerName=secure-app
Image=docker.io/library/nginx:alpine
PublishPort=8085:80
# Sécurité renforcée
ReadOnly=true
RunInit=true
DropCapability=ALL
AddCapability=NET_BIND_SERVICE
AddCapability=CHOWN
AddCapability=SETGID
AddCapability=SETUID
User=101
Group=101
# Tmpfs pour les fichiers temporaires
PodmanArgs=--tmpfs /tmp:rw,noexec,nosuid --tmpfs /var/cache/nginx:rw --tmpfs /var/run:rw

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

### Exemple 3 : Stack complète (web + db + cache)

```ini
# ~/.config/containers/systemd/app-network.network
[Network]
Subnet=10.90.0.0/24
```

```ini
# ~/.config/containers/systemd/app-db.container
[Unit]
Description=Application Database
After=network-online.target

[Container]
ContainerName=app-db
Image=docker.io/library/postgres:15-alpine
Network=app-network.network
EnvironmentFile=%h/.config/containers/app-db.env
Volume=app-db-data:/var/lib/postgresql/data:Z

[Service]
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```ini
# ~/.config/containers/systemd/app-cache.container
[Unit]
Description=Application Cache
After=network-online.target

[Container]
ContainerName=app-cache
Image=docker.io/library/redis:7-alpine
Network=app-network.network

[Service]
Restart=always

[Install]
WantedBy=default.target
```

```ini
# ~/.config/containers/systemd/app-web.container
[Unit]
Description=Application Web
After=app-db.service app-cache.service
Requires=app-db.service
Wants=app-cache.service

[Container]
ContainerName=app-web
Image=docker.io/library/nginx:alpine
Network=app-network.network
PublishPort=8086:80
Environment=DB_HOST=app-db
Environment=REDIS_HOST=app-cache

[Service]
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

Déploiement :

```bash
# Créer le fichier d'environnement DB
cat > ~/.config/containers/app-db.env << 'EOF'
POSTGRES_PASSWORD=secret
POSTGRES_USER=app
POSTGRES_DB=myapp
EOF
chmod 600 ~/.config/containers/app-db.env

# Déployer toute la stack
systemctl --user daemon-reload
systemctl --user enable --now app-db app-cache app-web
```

### Exemple 4 : Conteneur avec healthcheck

```ini
# ~/.config/containers/systemd/healthcheck-app.container
[Unit]
Description=Application avec healthcheck

[Container]
ContainerName=healthcheck-app
Image=docker.io/library/nginx:alpine
PublishPort=8087:80
# Healthcheck intégré
HealthCmd=curl -f http://localhost/ || exit 1
HealthInterval=30s
HealthRetries=3
HealthStartPeriod=10s
HealthTimeout=5s

[Service]
Restart=on-failure
# Redémarre si unhealthy
RestartSec=10

[Install]
WantedBy=default.target
```

### Exemple 5 : Construction d'image avec Quadlet

```ini
# ~/.config/containers/systemd/myapp.image
[Image]
# Chemin vers le Containerfile/Dockerfile
ContainerfilePath=%h/projects/myapp/Containerfile
# Tag de l'image résultante
ImageTag=localhost/myapp:latest
```

```ini
# ~/.config/containers/systemd/myapp.container
[Unit]
Description=Mon application custom
# S'assure que l'image est construite d'abord
After=myapp-image.service
Requires=myapp-image.service

[Container]
ContainerName=myapp
Image=localhost/myapp:latest
PublishPort=8088:8080

[Install]
WantedBy=default.target
```

---

## Mode utilisateur vs mode système

### Activer le linger pour les services utilisateur

Par défaut, les services utilisateur s'arrêtent quand l'utilisateur se déconnecte. Pour les garder actifs :

```bash
# Activer le linger pour l'utilisateur actuel
loginctl enable-linger

# Vérifier
loginctl show-user $USER | grep Linger
# Devrait afficher : Linger=yes

# Désactiver
loginctl disable-linger
```

### Déploiement en mode système (root)

Pour les services qui doivent démarrer au boot sans connexion utilisateur :

```bash
# Créer les fichiers Quadlet dans /etc/containers/systemd/
sudo mkdir -p /etc/containers/systemd

# Exemple
sudo tee /etc/containers/systemd/nginx-system.container << 'EOF'
[Unit]
Description=Nginx System Service

[Container]
ContainerName=nginx-system
Image=docker.io/library/nginx:alpine
PublishPort=80:80

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recharger et activer (sans --user)
sudo systemctl daemon-reload
sudo systemctl enable --now nginx-system
```

---

## Validation

Vous avez réussi si vous pouvez :

- Créer un fichier Quadlet `.container` et comprendre sa structure
- Installer un service Quadlet dans `~/.config/containers/systemd/`
- Utiliser `systemctl --user daemon-reload` après chaque modification
- Utiliser `systemctl --user` pour gérer les services
- Activer le démarrage automatique avec `enable`
- Consulter les logs avec `journalctl --user`
- Créer des dépendances entre services avec `Requires=` et `After=`
- Configurer des politiques de redémarrage avec `Restart=`
- Gérer des pods multi-conteneurs avec des fichiers `.pod`
- Créer des réseaux personnalisés avec des fichiers `.network`
- Activer le linger pour maintenir les services après déconnexion
- Comprendre la différence entre Quadlet et l'ancienne méthode `podman generate systemd`

---

## Résolution de problèmes courants

### Le service ne démarre pas après daemon-reload

```bash
# Vérifier la syntaxe du fichier Quadlet
/usr/libexec/podman/quadlet -dryrun -user

# Voir les erreurs de génération
journalctl --user -u systemd-*.service --since "5 minutes ago"

# Vérifier que le fichier est bien placé
ls -la ~/.config/containers/systemd/
```

### Le conteneur existe déjà (erreur de conflit)

```bash
# Supprimer le conteneur existant manuellement
podman rm -f nom-conteneur

# Puis redémarrer le service
systemctl --user restart nom-service
```

### Service s'arrête après la déconnexion

```bash
# Activer le linger
loginctl enable-linger $USER

# Vérifier
loginctl show-user $USER | grep Linger
```

### Voir l'unité systemd générée par Quadlet

```bash
# Afficher l'unité générée
systemctl --user cat nom-service

# Comparer avec le fichier Quadlet source
cat ~/.config/containers/systemd/nom-service.container
```

### Permissions refusées avec volumes

```bash
# Ajouter :Z pour SELinux
Volume=/chemin/host:/chemin/container:Z

# Vérifier les permissions
ls -laZ /chemin/host
```

### Nettoyer tous les services Quadlet

```bash
# Arrêter et désactiver
systemctl --user stop nom-service
systemctl --user disable nom-service

# Supprimer le fichier Quadlet
rm ~/.config/containers/systemd/nom-service.container

# Recharger
systemctl --user daemon-reload
systemctl --user reset-failed
```

---

## Migration depuis podman generate systemd

Si vous avez des services existants créés avec `podman generate systemd`, voici comment migrer vers Quadlet.

### Outil de migration : podlet

[podlet](https://github.com/containers/podlet) est un outil qui convertit les commandes `podman run` en fichiers Quadlet :

```bash
# Installation (Rust/Cargo)
cargo install podlet

# Conversion d'une commande podman run
podlet podman run -d --name nginx -p 8080:80 nginx:alpine

# Sortie :
# [Container]
# ContainerName=nginx
# Image=docker.io/library/nginx:alpine
# PublishPort=8080:80
```

### Migration manuelle

**Ancien service généré :**

```ini
# container-nginx.service (généré par podman generate systemd)
[Unit]
Description=Podman container-nginx.service

[Service]
Type=notify
ExecStartPre=/usr/bin/podman rm -f nginx
ExecStart=/usr/bin/podman run --name nginx -p 8080:80 nginx:alpine
ExecStop=/usr/bin/podman stop nginx
ExecStopPost=/usr/bin/podman rm -f nginx
Restart=on-failure

[Install]
WantedBy=default.target
```

**Nouveau fichier Quadlet équivalent :**

```ini
# nginx.container
[Unit]
Description=Nginx Web Server

[Container]
ContainerName=nginx
Image=docker.io/library/nginx:alpine
PublishPort=8080:80

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

### Étapes de migration

1. Identifier les services existants :
   ```bash
   ls ~/.config/systemd/user/container-*.service
   ```

2. Pour chaque service, créer le fichier Quadlet équivalent

3. Arrêter et désactiver l'ancien service :
   ```bash
   systemctl --user stop container-nginx.service
   systemctl --user disable container-nginx.service
   rm ~/.config/systemd/user/container-nginx.service
   ```

4. Créer et activer le nouveau Quadlet :
   ```bash
   # Créer nginx.container dans ~/.config/containers/systemd/
   systemctl --user daemon-reload
   systemctl --user enable --now nginx
   ```

---

## Bonnes pratiques

### Organisation des fichiers

```
~/.config/containers/systemd/
├── networks/           # Optionnel: sous-dossier pour les réseaux
├── app-network.network
├── app-db.container
├── app-cache.container
├── app-web.container
└── app-db.env          # À protéger: chmod 600
```

### Sécurité

1. **Mode utilisateur par défaut** : Privilégier `systemctl --user`
2. **Pas de secrets dans les fichiers Quadlet** : Utiliser `EnvironmentFile=`
3. **Permissions strictes** : `chmod 600` sur les fichiers `.env`
4. **Limites de ressources** : Utiliser `PodmanArgs=--memory=... --cpus=...`
5. **SELinux** : Toujours utiliser `:Z` ou `:z` sur les volumes

### Nommage

- **Préfixe cohérent** : `myapp-web`, `myapp-db`, `myapp-cache`
- **Descriptif** : Noms clairs et explicites
- **Pas de caractères spéciaux** : Lettres, chiffres, tirets uniquement

### Performance

1. **RestartSec=10** minimum pour éviter les boucles de redémarrage
2. **TimeoutStartSec** adapté au temps de démarrage réel
3. **Dépendances minimales** : N'ajouter que les dépendances nécessaires

---

## Référence rapide Quadlet

### Fichier .container minimal

```ini
[Container]
ContainerName=myapp
Image=docker.io/library/nginx:alpine
PublishPort=8080:80

[Install]
WantedBy=default.target
```

### Fichier .pod minimal

```ini
[Pod]
PodName=mypod
PublishPort=8080:80

[Install]
WantedBy=default.target
```

### Fichier .network minimal

```ini
[Network]
Subnet=10.89.0.0/24
```

### Fichier .volume minimal

```ini
[Volume]
# Utilise les options par défaut
```

### Workflow type

```bash
# 1. Créer le fichier Quadlet
vim ~/.config/containers/systemd/myapp.container

# 2. Recharger systemd
systemctl --user daemon-reload

# 3. Activer et démarrer
systemctl --user enable --now myapp

# 4. Vérifier
systemctl --user status myapp
journalctl --user -u myapp -f
```

---

## Suite

Passez au [TP5A - Sécurité](../TP5A-securite/) pour apprendre à sécuriser vos conteneurs Podman avec les meilleures pratiques de sécurité.

---

## Sources et références

- [Documentation officielle Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [Red Hat Blog - Make systemd better for Podman with Quadlet](https://www.redhat.com/en/blog/quadlet-podman)
- [Migration guide GitHub Discussion](https://github.com/containers/podman/discussions/20218)
- [podlet - Outil de conversion](https://github.com/containers/podlet)
