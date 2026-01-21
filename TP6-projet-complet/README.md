# TP6 - Projet Complet : Plateforme DevOps avec Monitoring

## 🎯 Objectifs

Ce TP bonus intègre **tous les concepts** des TP1 à TP5B dans un projet réel de bout en bout :
- Créer une stack complète multi-services
- Intégrer monitoring et observabilité
- Automatiser avec systemd
- Sécuriser l'ensemble
- Déployer sur le cloud (bonus)

**Durée estimée : 3 heures**

## 📋 Contexte du projet

Vous allez créer une **plateforme DevOps complète** comprenant :
- Une application web de gestion de tâches (Node.js + React)
- Une API REST (Express.js)
- Une base de données PostgreSQL
- Un cache Redis
- Un reverse proxy Nginx
- Monitoring avec Prometheus + Grafana
- Gestion centralisée des logs

Cette stack représente une architecture micro-services réaliste en production.

## 🏗️ Architecture de la solution

```
                    ┌─────────────────────────────────────────┐
                    │         Internet / Users                 │
                    └──────────────────┬──────────────────────┘
                                       │
                              Port 80/443 (HTTPS)
                                       │
                    ┌──────────────────▼──────────────────────┐
                    │        Nginx (Reverse Proxy)             │
                    │    - SSL Termination                     │
                    │    - Load Balancing                      │
                    │    - Static Files Cache                  │
                    └──────┬────────────────────┬──────────────┘
                           │                    │
                  Port 3000│                    │Port 9090/3001
                           │                    │
        ┌──────────────────▼──────┐    ┌──────▼───────────────┐
        │   Frontend (React)       │    │  Monitoring Stack    │
        │   - SPA Application      │    │  - Prometheus        │
        │   - Static Build         │    │  - Grafana           │
        └──────────────────────────┘    │  - Node Exporter     │
                                        └──────────────────────┘
                           │
                  Port 4000│ (API)
                           │
        ┌──────────────────▼──────────────────────┐
        │       API Backend (Express.js)           │
        │   - REST API                             │
        │   - Authentication JWT                   │
        │   - Business Logic                       │
        └──────┬────────────────────┬──────────────┘
               │                    │
      Port 5432│                    │Port 6379
               │                    │
    ┌──────────▼─────────┐   ┌─────▼──────────┐
    │   PostgreSQL       │   │     Redis       │
    │   - Primary DB     │   │   - Cache       │
    │   - Persistent     │   │   - Sessions    │
    └────────────────────┘   └─────────────────┘
```

### Volumes persistants
- `postgres_data` : Données PostgreSQL
- `grafana_data` : Configuration Grafana
- `prometheus_data` : Métriques Prometheus

### Réseaux
- `frontend-network` : Frontend ↔ Nginx
- `backend-network` : API ↔ DB ↔ Redis
- `monitoring-network` : Tous les services → Prometheus

## 🎓 Concepts intégrés

| Concept | TP d'origine | Application dans ce projet |
|---------|-------------|---------------------------|
| **Conteneurs simples** | TP1 | Tous les services conteneurisés |
| **Dockerfiles customs** | TP2 | Multi-stage pour API et Frontend |
| **Podman Compose** | TP3 | Orchestration complète 7 services |
| **Systemd** | TP4 | Auto-start au boot système |
| **Sécurité** | TP5A | Rootless, secrets, healthchecks |
| **Déploiement cloud** | TP5B | Terraform AWS (bonus) |

## 📁 Structure du projet

```
TP6-projet-complet/
├── README.md                      # Ce fichier
├── docker-compose.yml             # Orchestration complète
├── .env.example                   # Variables d'environnement
├── app/
│   ├── frontend/
│   │   ├── Dockerfile             # React build multi-stage
│   │   ├── package.json
│   │   └── src/
│   └── backend/
│       ├── Dockerfile             # Node.js API multi-stage
│       ├── package.json
│       ├── src/
│       └── tests/
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf                 # Configuration reverse proxy
│   └── ssl/                       # Certificats SSL
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml         # Configuration Prometheus
│   └── grafana/
│       └── dashboards/            # Dashboards JSON
├── scripts/
│   ├── setup.sh                   # Setup initial
│   ├── deploy.sh                  # Déploiement
│   ├── backup.sh                  # Sauvegarde DB
│   └── restore.sh                 # Restauration DB
├── quadlet/                       # Fichiers Quadlet (systemd)
│   ├── *.container                # Définitions des conteneurs
│   ├── *.network                  # Définitions des réseaux
│   ├── *.volume                   # Définitions des volumes
│   ├── deploy-quadlet.sh          # Script de déploiement
│   └── README.md                  # Documentation Quadlet
└── terraform/                     # Déploiement AWS (bonus)
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## 🚀 Démarrage rapide

```bash
# 1. Cloner et préparer
cd TP6-projet-complet
cp .env.example .env

# 2. Configurer les variables
nano .env

# 3. Setup initial (build + secrets)
./scripts/setup.sh

# 4. Lancer la stack complète
podman-compose up -d

# 5. Vérifier les services
podman-compose ps

# 6. Accéder aux interfaces
# - Application: http://localhost
# - API: http://localhost/api
# - Grafana: http://localhost:3001 (admin/admin)
# - Prometheus: http://localhost:9090
```

---

## 🔧 Dépannage

Si la stack ne fonctionne pas correctement, suivez cette checklist de vérification.

### Checklist de diagnostic

#### 1. Vérifier le fichier .env

```bash
# Le fichier .env existe-t-il ?
ls -la .env

# Si absent, le créer depuis l'exemple
cp .env.example .env

# Vérifier les valeurs configurées
cat .env | grep -E "POSTGRES|DB_|REDIS"
```

#### 2. Vérifier l'état des conteneurs

```bash
# État de tous les conteneurs
podman-compose ps

# Chercher les conteneurs en erreur (Exit, Error, Restarting)
podman ps -a | grep -E "Exit|Error|Restarting"
```

#### 3. Analyser les logs du backend

```bash
# Logs du backend (erreurs de connexion DB fréquentes)
podman logs taskplatform-api

# Chercher les erreurs de connexion
podman logs taskplatform-api 2>&1 | grep -i "error\|connect\|password"
```

#### 4. Vérifier la base de données PostgreSQL

```bash
# Vérifier que PostgreSQL est healthy
podman ps | grep taskplatform-db

# Tester la connexion manuellement
podman exec -it taskplatform-db psql -U taskuser -d taskdb -c "SELECT 1"

# Voir les logs PostgreSQL
podman logs taskplatform-db
```

#### 5. Vérifier Redis

```bash
# Tester la connexion Redis
podman exec -it taskplatform-redis redis-cli ping

# Avec mot de passe (si configuré)
podman exec -it taskplatform-redis redis-cli -a "$REDIS_PASSWORD" ping
```

#### 6. Tester les endpoints

```bash
# Health check de l'API
curl http://localhost/api/health

# Accès direct au backend (sans nginx)
curl http://localhost:4000/api/health
```

### Problèmes courants

| Symptôme | Cause probable | Solution |
|----------|---------------|----------|
| Backend ne démarre pas | Fichier .env manquant | `cp .env.example .env` |
| Erreur connexion DB | Mot de passe incorrect | Vérifier `POSTGRES_PASSWORD` dans .env |
| Redis connection refused | Redis pas démarré | `podman-compose up -d redis` |
| 502 Bad Gateway | Backend pas prêt | Attendre les healthchecks |
| Permission denied | Mode rootless | `podman system migrate` |

### Reset complet

Si rien ne fonctionne, effectuer un reset complet :

```bash
# Arrêter tout
podman-compose down -v

# Supprimer les volumes (ATTENTION: perte de données)
podman volume prune -f

# Reconstruire et redémarrer
podman-compose up -d --build

# Suivre les logs
podman-compose logs -f
```

---

## 📚 Exercice 1 : Préparation des Dockerfiles (45 min)

### Objectif
Créer des Dockerfiles optimisés pour chaque service avec multi-stage builds.

### 1.1 - Backend API (Node.js)

Créez `app/backend/Dockerfile` :

**Concepts appliqués :**
- Multi-stage build (TP2)
- Utilisateur non-root (TP5A)
- Healthcheck (TP3)
- Layer caching optimal (TP2)

**Caractéristiques :**
- Stage 1 : Build avec toutes les dépendances
- Stage 2 : Runtime avec seulement les dépendances de production
- Taille finale < 150MB
- Utilisateur `node` (non-root)
- Healthcheck sur `/api/health`

### 1.2 - Frontend React

Créez `app/frontend/Dockerfile` :

**Concepts appliqués :**
- Multi-stage build (TP2)
- Nginx pour servir les statics (TP2)
- Build optimisé (minification, compression)

**Caractéristiques :**
- Stage 1 : Build React (npm run build)
- Stage 2 : Nginx Alpine pour servir
- Taille finale < 50MB

### 1.3 - Reverse Proxy Nginx

Créez `nginx/Dockerfile` :

**Concepts appliqués :**
- Configuration custom (TP2)
- Gestion SSL (TP5A)
- Optimisation performance

**Caractéristiques :**
- Base Alpine
- Configuration custom avec upstream
- Gzip compression
- SSL/TLS ready

### 📝 Checklist Exercice 1

- [ ] Dockerfile backend avec multi-stage
- [ ] Dockerfile frontend avec multi-stage
- [ ] Dockerfile nginx custom
- [ ] Tous les Dockerfiles utilisent Alpine
- [ ] Utilisateurs non-root configurés
- [ ] Healthchecks définis
- [ ] Builds testés individuellement

**Validation :**
```bash
# Tester chaque build
cd app/backend && podman build -t task-api .
cd app/frontend && podman build -t task-frontend .
cd nginx && podman build -t task-nginx .

# Vérifier les tailles
podman images | grep task-
```

---

## 📚 Exercice 2 : Orchestration avec Compose (60 min)

### Objectif
Créer un `docker-compose.yml` complet orchestrant les 7 services avec leurs dépendances.

### 2.1 - Services de base

**Services à configurer :**

1. **PostgreSQL**
   - Image : `postgres:15-alpine`
   - Variables : `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
   - Volume : `postgres_data:/var/lib/postgresql/data`
   - Healthcheck : `pg_isready`
   - Network : `backend-network`

2. **Redis**
   - Image : `redis:7-alpine`
   - Configuration : Persistence AOF activée
   - Volume : `redis_data:/data`
   - Healthcheck : `redis-cli ping`
   - Network : `backend-network`

3. **Backend API**
   - Build : `./app/backend`
   - Dépend de : PostgreSQL, Redis
   - Environment : DB credentials, Redis URL
   - Ports : `4000:4000`
   - Networks : `backend-network`, `monitoring-network`

4. **Frontend**
   - Build : `./app/frontend`
   - Environment : `API_URL=http://backend:4000`
   - Ports : `3000:80`
   - Networks : `frontend-network`

5. **Nginx**
   - Build : `./nginx`
   - Dépend de : Frontend, Backend
   - Ports : `80:80`, `443:443`
   - Networks : `frontend-network`, `backend-network`

### 2.2 - Stack de monitoring

6. **Prometheus**
   - Image : `prom/prometheus:latest`
   - Config : `./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml`
   - Volume : `prometheus_data:/prometheus`
   - Ports : `9090:9090`
   - Network : `monitoring-network`

7. **Grafana**
   - Image : `grafana/grafana:latest`
   - Environment : `GF_SECURITY_ADMIN_PASSWORD`
   - Volume : `grafana_data:/var/lib/grafana`
   - Ports : `3001:3000`
   - Network : `monitoring-network`

### 2.3 - Configuration avancée

**Dépendances avec conditions :**
```yaml
depends_on:
  postgres:
    condition: service_healthy
  redis:
    condition: service_healthy
```

**Restart policies :**
```yaml
restart: unless-stopped
```

**Resource limits :**
```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M
```

### 📝 Checklist Exercice 2

- [ ] 7 services configurés
- [ ] 3 networks définis
- [ ] 4 volumes persistants
- [ ] Healthchecks sur tous les services
- [ ] Dépendances configurées
- [ ] Variables d'environnement via .env
- [ ] Resource limits définis
- [ ] Restart policies configurés

**Validation :**
```bash
# Valider la syntaxe
podman-compose config

# Lancer la stack
podman-compose up -d

# Vérifier tous les services
podman-compose ps
podman-compose logs -f

# Tester les healthchecks
for service in postgres redis backend; do
  podman healthcheck run $service
done
```

---

## 📚 Exercice 3 : Automatisation avec Quadlet (30 min)

### Objectif
Déployer TaskPlatform comme services systemd avec Quadlet (approche moderne, Podman 4.4+).

> **Note** : Quadlet remplace l'ancienne méthode `podman generate systemd` (dépréciée).
> Voir le [TP4](../TP4-systemd/) pour une introduction complète à Quadlet.

### 3.1 - Comprendre Quadlet

**Quadlet** transforme des fichiers de configuration déclaratifs en services systemd :

```
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  postgres.container │────▶│    Quadlet       │────▶│  postgres.service   │
│  (fichier déclaratif)│     │   (générateur)   │     │  (unité systemd)    │
└─────────────────────┘     └──────────────────┘     └─────────────────────┘
```

**Avantages de Quadlet :**
- Fichiers simples et déclaratifs (comme docker-compose)
- Mises à jour automatiques avec les nouvelles versions de Podman
- Gestion native des dépendances
- Intégration complète avec systemd

### 3.2 - Structure des fichiers Quadlet

Les fichiers sont fournis dans le répertoire `quadlet/` :

```
quadlet/
├── taskplatform-backend.network   # Réseau DB/Redis/API
├── taskplatform-frontend.network  # Réseau Nginx/React
├── taskplatform-monitoring.network # Réseau Prometheus/Grafana
├── postgres-data.volume           # Volume PostgreSQL
├── redis-data.volume              # Volume Redis
├── prometheus-data.volume         # Volume Prometheus
├── grafana-data.volume            # Volume Grafana
├── postgres.container             # PostgreSQL
├── redis.container                # Redis
├── backend.container              # API Node.js
├── frontend.container             # React
├── nginx.container                # Reverse proxy
├── prometheus.container           # Monitoring
├── grafana.container              # Dashboards
├── deploy-quadlet.sh              # Script d'installation
└── README.md                      # Documentation détaillée
```

### 3.3 - Installation avec le script

```bash
# Méthode recommandée : utiliser le script
cd quadlet/
./deploy-quadlet.sh install

# Le script va :
# 1. Vérifier les prérequis (Podman 4.4+, systemd)
# 2. Construire les images locales
# 3. Configurer les variables d'environnement
# 4. Copier les fichiers Quadlet
# 5. Démarrer les services
```

### 3.4 - Installation manuelle

```bash
# 1. Construire les images
podman build -t localhost/taskplatform-backend:latest ./app/backend
podman build -t localhost/taskplatform-frontend:latest ./app/frontend
podman build -t localhost/taskplatform-nginx:latest ./nginx

# 2. Configurer les variables d'environnement
mkdir -p ~/.config/containers
cp quadlet/taskplatform.env.example ~/.config/containers/taskplatform.env
# Éditer le fichier avec vos mots de passe

# 3. Installer les fichiers Quadlet
mkdir -p ~/.config/containers/systemd
cp quadlet/*.container quadlet/*.network quadlet/*.volume ~/.config/containers/systemd/

# 4. Recharger systemd
systemctl --user daemon-reload

# 5. Démarrer les services
systemctl --user enable --now postgres redis backend frontend nginx prometheus grafana
```

### 3.5 - Gestion des services

```bash
# Statut de tous les services
systemctl --user status postgres redis backend frontend nginx prometheus grafana

# Logs d'un service
journalctl --user -u backend -f

# Redémarrer un service
systemctl --user restart backend

# Arrêter tous les services
systemctl --user stop nginx grafana prometheus frontend backend redis postgres

# Voir l'unité systemd générée par Quadlet
systemctl --user cat backend
```

### 3.6 - Vérifier le déploiement

```bash
# Vérifier que les services sont actifs
./quadlet/deploy-quadlet.sh status

# Tester l'application
curl http://localhost/api/health
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3001/api/health  # Grafana
```

### 📝 Checklist Exercice 3

- [ ] Images construites (`podman images | grep taskplatform`)
- [ ] Variables d'environnement configurées
- [ ] Fichiers Quadlet installés dans `~/.config/containers/systemd/`
- [ ] Services démarrés avec `systemctl --user`
- [ ] Application accessible sur http://localhost
- [ ] Services activés au démarrage (`enable`)
- [ ] Test de redémarrage effectué

**Validation :**
```bash
# Lister les services
systemctl --user list-units | grep container-

# Test de redémarrage complet
systemctl --user restart pod-taskplatform.service

# Vérifier que tous démarrent
sleep 30
systemctl --user status pod-taskplatform.service
podman ps
```

---

## 📚 Exercice 4 : Sécurisation (45 min)

### Objectif
Appliquer toutes les bonnes pratiques de sécurité sur la stack.

### 4.1 - Mode Rootless

**Vérifications :**
```bash
# Vérifier mode rootless
podman system info | grep -i rootless

# Vérifier user namespaces
podman unshare cat /proc/self/uid_map
```

**Actions :**
- Tous les conteneurs en rootless
- Utilisateurs non-root dans les Dockerfiles
- Pas de `--privileged`

### 4.2 - Gestion des secrets

**Créer des secrets Podman :**
```bash
# Créer les secrets
echo "mydbpassword" | podman secret create db_password -
echo "myjwttoken" | podman secret create jwt_secret -
echo "grafana_admin_password" | podman secret create grafana_password -
```

**Utiliser dans compose :**
```yaml
services:
  postgres:
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    external: true
  jwt_secret:
    external: true
```

### 4.3 - Capabilities et ressources

**Limiter les capabilities :**
```yaml
services:
  backend:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Si besoin port < 1024
```

**Limiter les ressources :**
```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 4.4 - Scan de vulnérabilités

```bash
# Scanner toutes les images
for image in task-api task-frontend task-nginx postgres:15-alpine redis:7-alpine; do
  echo "Scanning $image..."
  trivy image $image --severity HIGH,CRITICAL
done
```

### 4.5 - Configuration SSL/TLS

**Générer certificats auto-signés (dev) :**
```bash
./scripts/generate-ssl.sh
```

**Configurer Nginx pour SSL :**
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
}
```

### 📝 Checklist Exercice 4

- [ ] Mode rootless vérifié
- [ ] Secrets Podman créés et utilisés
- [ ] Capabilities limitées
- [ ] Resource limits définis
- [ ] Images scannées (Trivy)
- [ ] SSL/TLS configuré
- [ ] Pas de credentials en clair
- [ ] Healthchecks sur tous les services

**Validation :**
```bash
# Vérifier rootless
podman system info | grep -A5 rootless

# Vérifier secrets
podman secret ls

# Vérifier capabilities
podman inspect backend | jq '.[0].HostConfig.CapDrop'

# Test SSL
curl -k https://localhost
```

---

## 🎁 Exercice Bonus : Déploiement AWS (optionnel)

### Objectif
Déployer la stack complète sur AWS avec Terraform.

### Architecture AWS

```
AWS Cloud
├── VPC (default)
│   └── EC2 Instance (t3.medium)
│       ├── Amazon Linux 2023
│       ├── Podman + podman-compose
│       └── Stack TaskPlatform complète
└── Security Group
    ├── SSH (22)
    ├── Application (8080)
    ├── Grafana (3001)
    └── Prometheus (9090)
```

### Prérequis

- Terraform >= 1.0
- AWS CLI configuré
- Une paire de clés SSH dans AWS

### Déploiement

Les fichiers Terraform sont disponibles dans le dossier `terraform/`.

```bash
cd terraform

# Créer une paire de clés SSH (si nécessaire)
aws ec2 create-key-pair --key-name taskplatform-key \
    --query 'KeyMaterial' --output text > ~/.ssh/taskplatform-key.pem
chmod 400 ~/.ssh/taskplatform-key.pem

# Initialiser Terraform
terraform init

# Vérifier le plan
terraform plan

# Déployer (confirmer avec 'yes')
terraform apply

# Récupérer les URLs
terraform output
```

### Accès aux services

```bash
# Se connecter en SSH
ssh -i ~/.ssh/taskplatform-key.pem ec2-user@$(terraform output -raw public_ip)

# Une fois connecté, vérifier l'état
tp status
tp health

# URLs des services
terraform output app_url        # Application
terraform output grafana_url    # Grafana
terraform output prometheus_url # Prometheus
```

Le mot de passe Grafana est généré automatiquement :
```bash
cat ~/grafana-credentials.txt
```

### Destruction

```bash
terraform destroy
```

### 📝 Checklist Bonus

- [ ] Clé SSH créée dans AWS
- [ ] `terraform init` réussi
- [ ] `terraform apply` réussi
- [ ] Instance EC2 accessible en SSH
- [ ] Application accessible sur port 8080
- [ ] Grafana accessible sur port 3001
- [ ] Prometheus accessible sur port 9090

---

## ✅ Validation finale du projet

### Checklist complète

#### Infrastructure
- [ ] 7 services démarrent correctement
- [ ] Tous les healthchecks passent
- [ ] Volumes persistants fonctionnent
- [ ] Networks isolent correctement

#### Application
- [ ] Frontend accessible sur port 80/443
- [ ] API répond sur /api/*
- [ ] Base de données connectée
- [ ] Cache Redis fonctionne
- [ ] Sessions utilisateur persistantes

#### Monitoring
- [ ] Prometheus scrape toutes les métriques
- [ ] Grafana affiche les dashboards
- [ ] Alertes configurées
- [ ] Logs centralisés

#### Sécurité
- [ ] Mode rootless actif
- [ ] Secrets utilisés (pas de mots de passe en clair)
- [ ] SSL/TLS configuré
- [ ] Capabilities limitées
- [ ] Aucune vulnérabilité HIGH/CRITICAL

#### Automatisation
- [ ] Services Quadlet installés (`~/.config/containers/systemd/`)
- [ ] Auto-start au boot fonctionne (`systemctl --user enable`)
- [ ] Scripts de backup/restore testés
- [ ] Documentation à jour

### Tests fonctionnels

```bash
# 1. Test complet de la stack
./scripts/test-complete.sh

# 2. Test des endpoints
curl http://localhost/api/health
curl http://localhost/api/tasks
curl http://localhost

# 3. Test monitoring
curl http://localhost:9090/api/v1/targets
curl http://localhost:3001/api/health

# 4. Test persistence
# Créer des données
curl -X POST http://localhost/api/tasks -d '{"title":"Test"}'

# Redémarrer
podman-compose restart

# Vérifier données toujours présentes
curl http://localhost/api/tasks

# 5. Test backup/restore
./scripts/backup.sh
./scripts/restore.sh backup-2024-01-06.sql
```

### Métriques de succès

- ✅ **Temps de démarrage** : < 2 minutes
- ✅ **Disponibilité** : 100% après démarrage
- ✅ **Réponse API** : < 200ms
- ✅ **Utilisation mémoire** : < 4GB total
- ✅ **Utilisation CPU** : < 50% en idle

---

## 📊 Métriques et Monitoring

### Dashboards Grafana

**Dashboard 1 : Vue d'ensemble**
- Nombre de conteneurs actifs
- Utilisation CPU/Mémoire par service
- Trafic réseau
- Uptime

**Dashboard 2 : Application**
- Requêtes API par seconde
- Temps de réponse moyen
- Taux d'erreur 5xx
- Connexions base de données

**Dashboard 3 : Infrastructure**
- Utilisation disque
- I/O réseau
- Métriques PostgreSQL
- Métriques Redis

### Alertes Prometheus

```yaml
groups:
- name: services
  rules:
  - alert: ServiceDown
    expr: up == 0
    for: 1m
    annotations:
      summary: "Service {{ $labels.instance }} is down"

  - alert: HighMemoryUsage
    expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
    for: 5m
```

---

## 🛠️ Scripts utilitaires

### setup.sh
```bash
#!/bin/bash
# Setup initial complet
# - Génère secrets
# - Build images
# - Initialise DB
# - Configure monitoring
```

### deploy.sh
```bash
#!/bin/bash
# Déploiement complet
# - Pull images
# - Start stack
# - Attends healthchecks
# - Affiche status
```

### backup.sh
```bash
#!/bin/bash
# Sauvegarde PostgreSQL
podman exec postgres pg_dump -U taskuser taskdb > backup-$(date +%Y%m%d).sql
```

### restore.sh
```bash
#!/bin/bash
# Restauration PostgreSQL
podman exec -i postgres psql -U taskuser taskdb < $1
```

### test-complete.sh
```bash
#!/bin/bash
# Tests end-to-end
# - Vérifie tous les services
# - Test les endpoints
# - Vérifie monitoring
```

---

## 📚 Documentation et ressources

### Architecture decisions

**Pourquoi PostgreSQL ?**
- Base relationnelle robuste
- Support transactions ACID
- Excellent pour données structurées

**Pourquoi Redis ?**
- Cache ultra-rapide
- Sessions distribuées
- Pub/Sub pour temps réel

**Pourquoi Nginx ?**
- Reverse proxy performant
- SSL termination
- Load balancing

**Pourquoi Prometheus + Grafana ?**
- Standard industrie monitoring
- Métriques détaillées
- Dashboards personnalisables

### Bonnes pratiques appliquées

1. **12-Factor App**
   - Configuration via environnement
   - Logs en stdout
   - Stateless services

2. **Sécurité**
   - Principe du moindre privilège
   - Secrets managés
   - Scan régulier vulnérabilités

3. **Observabilité**
   - Logging centralisé
   - Métriques exposées
   - Healthchecks complets

4. **Résilience**
   - Restart automatique
   - Healthchecks avec retry
   - Dépendances explicites

---

## 🎓 Compétences acquises

À la fin de ce TP, vous maîtrisez :

### Technique
- ✅ Architecture micro-services complète
- ✅ Orchestration multi-conteneurs complexe
- ✅ Multi-stage builds optimisés
- ✅ Networking avancé Podman
- ✅ Gestion des secrets
- ✅ Monitoring et observabilité
- ✅ Automatisation Quadlet/systemd
- ✅ Déploiement cloud

### Opérationnel
- ✅ Backup et restore
- ✅ Debugging stack complexe
- ✅ Gestion des logs
- ✅ Alerting et monitoring
- ✅ Scaling horizontal
- ✅ Blue/Green deployment

### Sécurité
- ✅ Mode rootless complet
- ✅ Gestion secrets
- ✅ SSL/TLS
- ✅ Scan vulnérabilités
- ✅ Isolation réseau
- ✅ Resource quotas

---

## 🚀 Pour aller plus loin

### Améliorations possibles

1. **High Availability**
   - PostgreSQL réplication
   - Redis cluster
   - Multiple instances API

2. **CI/CD**
   - GitHub Actions
   - Tests automatisés
   - Déploiement automatique

3. **Monitoring avancé**
   - Distributed tracing (Jaeger)
   - Log aggregation (ELK)
   - APM (Application Performance Monitoring)

4. **Scaling**
   - Kubernetes migration
   - Service mesh (Istio)
   - Load testing (k6)

### Ressources

- [12-Factor App Methodology](https://12factor.net/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [Podman Documentation](https://docs.podman.io/)

---

## 🎉 Félicitations !

Vous avez complété le TP Bonus le plus avancé du workshop !

Vous êtes maintenant capable de :
- Concevoir et déployer des architectures micro-services
- Orchestrer des stacks complexes avec Podman
- Monitorer et maintenir des applications en production
- Sécuriser vos déploiements
- Automatiser vos workflows DevOps

**Prochaines étapes :**
- Déployer votre propre projet avec cette stack
- Contribuer à des projets open-source
- Approfondir Kubernetes pour le scaling
- Explorer les service meshes

**Partagez vos réalisations !** 🎊

---

**Durée réelle : 3h** (sans le bonus AWS)
**Niveau : Expert** ⭐⭐⭐⭐⭐

[← Retour au sommaire](../README.md)
