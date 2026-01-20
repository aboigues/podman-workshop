# Déploiement TaskPlatform avec Quadlet

Ce répertoire contient les fichiers Quadlet pour déployer TaskPlatform comme services systemd.

## Prérequis

- Podman 4.4+ (`podman --version`)
- systemd avec mode utilisateur (`systemctl --user status`)
- Images construites localement (voir étape 1)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         QUADLET SERVICES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                   │
│  │  nginx   │    │prometheus│    │ grafana  │                   │
│  │  :80/443 │    │  :9090   │    │  :3001   │                   │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘                   │
│       │               │               │                          │
│  ┌────┴────┐     ┌────┴───────────────┴────┐                    │
│  │frontend │     │   monitoring-network     │                    │
│  │ network │     └─────────────────────────┘                    │
│  └────┬────┘                                                     │
│       │                                                          │
│  ┌────┴─────┐    ┌──────────────────────────┐                   │
│  │ frontend │    │     backend-network       │                   │
│  └──────────┘    │  ┌────────┐ ┌────────┐   │                   │
│                  │  │postgres│ │ redis  │   │                   │
│                  │  │  :5432 │ │ :6379  │   │                   │
│                  │  └────────┘ └────────┘   │                   │
│                  │       ┌────────┐         │                   │
│                  │       │backend │         │                   │
│                  │       │ :4000  │         │                   │
│                  │       └────────┘         │                   │
│                  └──────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Fichiers Quadlet

| Fichier | Type | Description |
|---------|------|-------------|
| `taskplatform-backend.network` | Network | Réseau interne (DB, Redis, API) |
| `taskplatform-frontend.network` | Network | Réseau frontend (Nginx, React) |
| `taskplatform-monitoring.network` | Network | Réseau monitoring (Prometheus, Grafana) |
| `postgres-data.volume` | Volume | Données PostgreSQL |
| `redis-data.volume` | Volume | Données Redis |
| `prometheus-data.volume` | Volume | Métriques Prometheus |
| `grafana-data.volume` | Volume | Dashboards Grafana |
| `postgres.container` | Container | Base de données PostgreSQL |
| `redis.container` | Container | Cache Redis |
| `backend.container` | Container | API Node.js |
| `frontend.container` | Container | Application React |
| `nginx.container` | Container | Reverse proxy |
| `prometheus.container` | Container | Collecte de métriques |
| `grafana.container` | Container | Visualisation |

## Installation

### Étape 1 : Construire les images

```bash
cd /chemin/vers/TP6-projet-complet

# Construire les 3 images personnalisées
podman build -t localhost/taskplatform-backend:latest ./app/backend
podman build -t localhost/taskplatform-frontend:latest ./app/frontend
podman build -t localhost/taskplatform-nginx:latest ./nginx

# Vérifier
podman images | grep taskplatform
```

### Étape 2 : Configurer les variables d'environnement

```bash
# Créer le répertoire de configuration
mkdir -p ~/.config/containers

# Copier et adapter le fichier d'environnement
cat > ~/.config/containers/taskplatform.env << 'EOF'
# PostgreSQL
POSTGRES_DB=taskplatform
POSTGRES_USER=taskplatform
POSTGRES_PASSWORD=votre_mot_de_passe_securise

# Redis
REDIS_PASSWORD=votre_redis_password

# Backend
DB_NAME=taskplatform
DB_USER=taskplatform
DB_PASSWORD=votre_mot_de_passe_securise
JWT_SECRET=votre_jwt_secret_tres_long
JWT_EXPIRES_IN=7d

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin_password
GF_SERVER_ROOT_URL=http://localhost:3001
EOF

# Sécuriser le fichier
chmod 600 ~/.config/containers/taskplatform.env
```

### Étape 3 : Préparer les fichiers de configuration

```bash
# Créer le répertoire pour les fichiers de configuration
mkdir -p ~/taskplatform

# Copier les fichiers nécessaires
cp -r /chemin/vers/TP6-projet-complet/monitoring ~/taskplatform/
cp -r /chemin/vers/TP6-projet-complet/nginx ~/taskplatform/
```

### Étape 4 : Installer les fichiers Quadlet

```bash
# Créer le répertoire Quadlet utilisateur
mkdir -p ~/.config/containers/systemd

# Copier tous les fichiers Quadlet
cp *.container *.network *.volume ~/.config/containers/systemd/

# Recharger systemd
systemctl --user daemon-reload

# Vérifier que les services sont détectés
systemctl --user list-unit-files | grep taskplatform
```

### Étape 5 : Démarrer les services

```bash
# Démarrer dans l'ordre (les dépendances sont gérées automatiquement)
systemctl --user enable --now postgres
systemctl --user enable --now redis
systemctl --user enable --now backend
systemctl --user enable --now frontend
systemctl --user enable --now nginx
systemctl --user enable --now prometheus
systemctl --user enable --now grafana

# Ou tout d'un coup (systemd gère l'ordre)
systemctl --user enable --now postgres redis backend frontend nginx prometheus grafana
```

## Commandes utiles

### Vérifier le statut

```bash
# Tous les services TaskPlatform
systemctl --user status postgres redis backend frontend nginx prometheus grafana

# Un service spécifique
systemctl --user status backend

# Logs en temps réel
journalctl --user -u backend -f
```

### Gestion des services

```bash
# Arrêter tous les services
systemctl --user stop nginx grafana prometheus frontend backend redis postgres

# Redémarrer un service
systemctl --user restart backend

# Désactiver le démarrage automatique
systemctl --user disable postgres redis backend frontend nginx prometheus grafana
```

### Debugging

```bash
# Voir les logs d'un service
journalctl --user -u backend --since "10 minutes ago"

# Vérifier la syntaxe des fichiers Quadlet
/usr/libexec/podman/quadlet -dryrun -user

# Voir l'unité systemd générée
systemctl --user cat backend
```

## Persistance après déconnexion

Pour que les services continuent de fonctionner après déconnexion :

```bash
# Activer le linger pour votre utilisateur
loginctl enable-linger $USER

# Vérifier
loginctl show-user $USER | grep Linger
```

> **Note WSL** : `loginctl enable-linger` ne fonctionne pas sous WSL. Les services s'arrêteront à la fermeture de WSL.

## Différences avec Docker Compose

| Aspect | Docker Compose | Quadlet |
|--------|---------------|---------|
| Gestion | `podman-compose up/down` | `systemctl --user start/stop` |
| Logs | `podman-compose logs` | `journalctl --user -u service` |
| Démarrage auto | Non (sauf config) | Oui avec `enable` |
| Dépendances | `depends_on` | `After=`, `Requires=` |
| Fichiers | 1 docker-compose.yml | 1 fichier par ressource |

## Nettoyage complet

```bash
# Arrêter et désactiver tous les services
systemctl --user stop nginx grafana prometheus frontend backend redis postgres
systemctl --user disable nginx grafana prometheus frontend backend redis postgres

# Supprimer les fichiers Quadlet
rm ~/.config/containers/systemd/taskplatform-*.network
rm ~/.config/containers/systemd/*-data.volume
rm ~/.config/containers/systemd/{postgres,redis,backend,frontend,nginx,prometheus,grafana}.container

# Recharger systemd
systemctl --user daemon-reload
systemctl --user reset-failed

# Supprimer les volumes (ATTENTION: perte de données)
podman volume rm taskplatform-postgres-data taskplatform-redis-data taskplatform-prometheus-data taskplatform-grafana-data

# Supprimer les réseaux
podman network rm taskplatform-backend taskplatform-frontend taskplatform-monitoring

# Supprimer les images (optionnel)
podman rmi localhost/taskplatform-backend localhost/taskplatform-frontend localhost/taskplatform-nginx
```
