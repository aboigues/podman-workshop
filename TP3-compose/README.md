# TP3 - Orchestration avec Podman Compose

## Objectifs
- Gérer des applications multi-conteneurs avec un seul fichier de configuration
- Comprendre la syntaxe et la structure d'un fichier docker-compose.yml
- Orchestrer des services avec leurs dépendances
- Configurer des réseaux et volumes persistants
- Implémenter des health checks et gestion des dépendances
- Gérer des variables d'environnement et secrets

## Prérequis
- Podman installé
- podman-compose installé (`pip install podman-compose`)
- Accès terminal
- Connexion internet

## Démarrage rapide
```bash
# Stack simple (Nginx + Redis)
cd simple-stack
podman-compose up -d

# WebApp avec base de données
cd webapp-db
podman-compose up -d

# Test rapide
./test-all-stacks.sh
```

---

## Introduction à Podman Compose

**Podman Compose** est un outil d'orchestration qui permet de définir et gérer des applications multi-conteneurs à l'aide d'un fichier YAML. Il est compatible avec la syntaxe Docker Compose.

### Avantages de Podman Compose

- **Configuration centralisée** : Un seul fichier YAML pour décrire tous les services
- **Reproductibilité** : Garantit un environnement identique sur différentes machines
- **Gestion simplifiée** : Une commande pour démarrer/arrêter tous les services
- **Orchestration** : Gère automatiquement les dépendances entre services
- **Isolation réseau** : Crée automatiquement un réseau dédié pour la stack

---

## Structure d'un fichier docker-compose.yml

### Exemple de base (simple-stack)

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    container_name: simple-web
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped
    networks:
      - simple-network

  redis:
    image: redis:7-alpine
    container_name: simple-redis
    ports:
      - "6379:6379"
    restart: unless-stopped
    networks:
      - simple-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

networks:
  simple-network:
    driver: bridge
```

### Explications ligne par ligne

**`version: '3.8'`**
- Spécifie la version du format Compose
- Version 3.8 est largement supportée et recommandée
- Détermine quelles fonctionnalités sont disponibles

**Section `services:`**

Définit tous les conteneurs de l'application.

**`web:` (nom du service)**
- Nom logique du service
- Utilisé pour la résolution DNS entre conteneurs
- Les autres services peuvent y accéder via `http://web`

**`image: nginx:alpine`**
- Image à utiliser pour ce service
- Format : `IMAGE:TAG`
- Alternative : `build:` pour construire depuis un Dockerfile

**`container_name: simple-web`**
- Nom du conteneur créé
- Optionnel (par défaut : `<projet>_<service>_<numéro>`)
- Utile pour identifier facilement le conteneur

**`ports:`**
- Mapping des ports hôte:conteneur
- Format : `"PORT_HOTE:PORT_CONTENEUR"`
- `"8080:80"` : Port 80 du conteneur accessible sur le port 8080 de l'hôte

**`volumes:`**
- Monte des volumes ou répertoires
- Format : `SOURCE:DESTINATION[:OPTIONS]`
- `./html:/usr/share/nginx/html:ro`
  - `./html` : Répertoire source (relatif au docker-compose.yml)
  - `/usr/share/nginx/html` : Point de montage dans le conteneur
  - `:ro` : Read-only (optionnel)

**`restart: unless-stopped`**
- Politique de redémarrage du conteneur
- Options :
  - `no` : Ne jamais redémarrer (défaut)
  - `always` : Toujours redémarrer
  - `on-failure` : Redémarrer en cas d'erreur uniquement
  - `unless-stopped` : Toujours redémarrer sauf si arrêté manuellement

**`networks:`**
- Réseaux auxquels le service est connecté
- Permet la communication entre services
- DNS automatique : les services s'appellent par leur nom

**`healthcheck:`**
- Vérifie périodiquement la santé du service
- **`test`** : Commande à exécuter pour tester la santé
  - `["CMD", "redis-cli", "ping"]` : Exécute `redis-cli ping`
  - `["CMD-SHELL", "curl -f http://localhost"]` : Utilise le shell
- **`interval`** : Fréquence de vérification (10s = toutes les 10 secondes)
- **`timeout`** : Temps maximum pour une vérification (3s)
- **`retries`** : Nombre d'échecs avant de marquer comme "unhealthy" (3)

**Section `networks:`**
- Définit les réseaux disponibles
- **`simple-network:`** : Nom du réseau
- **`driver: bridge`** : Type de réseau (bridge par défaut)

---

## Exemple avancé avec dépendances (webapp-db)

```yaml
version: '3.8'

services:
  web:
    build:
      context: ./app
    container_name: webapp
    ports:
      - "8080:80"
    environment:
      DB_HOST: database
      DB_NAME: webapp
      DB_USER: webapp_user
      DB_PASS: webapp_pass
    depends_on:
      database:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - webapp-network

  database:
    image: postgres:15-alpine
    container_name: webapp-db
    environment:
      POSTGRES_DB: webapp
      POSTGRES_USER: webapp_user
      POSTGRES_PASSWORD: webapp_pass
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - webapp-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U webapp_user -d webapp"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  db_data:

networks:
  webapp-network:
    driver: bridge
```

### Nouvelles directives expliquées

**`build:`**
- Construit l'image à partir d'un Dockerfile
- **`context: ./app`** : Répertoire contenant le Dockerfile
- Alternative à `image:` pour des images personnalisées

**`environment:`**
- Définit les variables d'environnement
- Format : `CLE: VALEUR`
- Utilisées pour la configuration de l'application

**`depends_on:`**
- Définit les dépendances entre services
- Format simple : `depends_on: - database`
- Format avancé avec condition :
  ```yaml
  depends_on:
    database:
      condition: service_healthy
  ```
- Conditions possibles :
  - `service_started` : Attend que le service démarre (défaut)
  - `service_healthy` : Attend que le healthcheck soit OK
  - `service_completed_successfully` : Attend la fin avec succès

**`volumes:` (section racine)**
- Définit des volumes nommés persistants
- `db_data:` : Volume géré par Podman
- Les données persistent même après `podman-compose down`

**Types de volumes :**

1. **Volume nommé** : `db_data:/var/lib/postgresql/data`
   - Géré par Podman
   - Persiste après suppression du conteneur
   - Partageable entre conteneurs

2. **Bind mount** : `./html:/usr/share/nginx/html`
   - Monte un répertoire de l'hôte
   - Modifications visibles immédiatement
   - Utile pour le développement

3. **Volume avec initialisation** : `./init.sql:/docker-entrypoint-initdb.d/init.sql:ro`
   - Monte un fichier spécifique
   - Mode lecture seule (`:ro`)
   - Utilisé pour l'initialisation de la base de données

---

## Exercices pratiques

### Exercice 1 : Démarrer une stack simple

```bash
cd simple-stack
podman-compose up -d
```

#### Explications détaillées

**`podman-compose up -d`**

- **`up`** : Crée et démarre tous les services définis dans docker-compose.yml
- **`-d`** (detach) : Lance en arrière-plan
- Actions effectuées automatiquement :
  1. Crée le réseau s'il n'existe pas
  2. Crée les volumes nommés s'ils n'existent pas
  3. Pull les images nécessaires si absentes
  4. Crée et démarre les conteneurs dans l'ordre des dépendances
  5. Configure les réseaux et volumes

**Options supplémentaires :**
- **`--build`** : Force la reconstruction des images
- **`--force-recreate`** : Recrée tous les conteneurs même si rien n'a changé
- **`--no-deps`** : Ne démarre pas les services dépendants

**Vérifier l'état :**

```bash
# Lister les conteneurs de la stack
podman-compose ps

# Vérifier les logs
podman-compose logs

# Tester le service web
curl http://localhost:8080

# Vérifier Redis
podman exec simple-redis redis-cli ping
```

---

### Exercice 2 : Consulter les logs

```bash
# Logs de tous les services
podman-compose logs

# Logs d'un service spécifique
podman-compose logs web

# Logs en temps réel
podman-compose logs -f

# Logs d'un service en temps réel
podman-compose logs -f redis
```

#### Explications détaillées

**`podman-compose logs`**

- Affiche les logs de tous les services
- Préfixe chaque ligne avec le nom du service
- Affiche l'historique complet par défaut

**`podman-compose logs web`**

- Affiche uniquement les logs du service `web`
- Utile pour déboguer un service spécifique

**`podman-compose logs -f`**

- **`-f`** (follow) : Mode suivi en temps réel
- Affiche les nouveaux logs au fur et à mesure
- Interrompre avec `Ctrl+C`
- Combine les logs de tous les services

**Options supplémentaires :**
- **`--tail=N`** : Affiche les N dernières lignes
- **`--timestamps`** : Ajoute l'horodatage
- **`--no-color`** : Désactive la coloration

---

### Exercice 3 : Gestion du cycle de vie

```bash
# Arrêter les services sans les supprimer
podman-compose stop

# Redémarrer les services
podman-compose start

# Redémarrer (stop + start)
podman-compose restart

# Arrêter et supprimer tout
podman-compose down

# Arrêter et supprimer avec volumes
podman-compose down -v
```

#### Explications détaillées

**`podman-compose stop`**

- Arrête tous les conteneurs de la stack
- Les conteneurs restent présents (état "Exited")
- Les réseaux et volumes sont conservés
- Utilise un arrêt gracieux (SIGTERM puis SIGKILL)

**`podman-compose start`**

- Démarre les conteneurs existants arrêtés
- Ne recrée PAS les conteneurs
- Conserve la configuration initiale

**`podman-compose restart`**

- Équivalent à `stop` + `start`
- Utile après modification de configuration
- Options :
  - **`-t`** : Timeout avant SIGKILL (défaut : 10s)

**`podman-compose down`**

- **Arrête ET supprime** tous les conteneurs de la stack
- Supprime également le réseau créé
- **NE supprime PAS** les volumes nommés par défaut
- **NE supprime PAS** les images

**`podman-compose down -v`**

- **`-v`** (volumes) : Supprime aussi les volumes nommés
- ⚠️ **ATTENTION** : Supprime les données persistantes !
- À utiliser avec précaution en production

**Options supplémentaires :**
- **`--rmi all`** : Supprime toutes les images utilisées
- **`--rmi local`** : Supprime uniquement les images construites localement
- **`--remove-orphans`** : Supprime les conteneurs orphelins

---

### Exercice 4 : Stack avec base de données

```bash
cd webapp-db
podman-compose up -d

# Attendre que la base soit prête (healthcheck)
podman-compose ps

# Vérifier les logs de la base
podman-compose logs database

# Tester l'application
curl http://localhost:8080
```

#### Explications détaillées

**Ordre de démarrage avec `depends_on`**

Avec cette configuration :
```yaml
depends_on:
  database:
    condition: service_healthy
```

1. `database` démarre en premier
2. Le healthcheck s'exécute toutes les 10s
3. Après 5 tentatives réussies, `database` est "healthy"
4. Seulement alors, `web` démarre
5. `web` peut se connecter à la base immédiatement

**Sans healthcheck**, le service web pourrait démarrer avant que PostgreSQL soit prêt, causant des erreurs de connexion.

**Vérifier le healthcheck :**

```bash
# Voir l'état de santé
podman inspect webapp-db --format='{{.State.Health.Status}}'

# Voir les logs du healthcheck
podman inspect webapp-db --format='{{json .State.Health}}' | jq
```

---

## Commandes essentielles - Référence complète

### Gestion du cycle de vie

| Commande | Description | Options courantes |
|----------|-------------|-------------------|
| `podman-compose up` | Crée et démarre tous les services | `-d`, `--build`, `--force-recreate`, `--no-deps` |
| `podman-compose down` | Arrête et supprime tous les services | `-v`, `--rmi`, `--remove-orphans` |
| `podman-compose start` | Démarre les services existants | `[SERVICE...]` |
| `podman-compose stop` | Arrête les services | `-t`, `[SERVICE...]` |
| `podman-compose restart` | Redémarre les services | `-t`, `[SERVICE...]` |
| `podman-compose pause` | Met en pause tous les processus | `[SERVICE...]` |
| `podman-compose unpause` | Reprend l'exécution | `[SERVICE...]` |

### Consultation et monitoring

| Commande | Description | Options courantes |
|----------|-------------|-------------------|
| `podman-compose ps` | Liste les conteneurs de la stack | `-a`, `--services`, `--filter` |
| `podman-compose logs` | Affiche les logs | `-f`, `--tail`, `--timestamps`, `[SERVICE...]` |
| `podman-compose top` | Affiche les processus en cours | `[SERVICE...]` |
| `podman-compose events` | Affiche les événements en temps réel | `--json` |

### Construction et images

| Commande | Description | Options courantes |
|----------|-------------|-------------------|
| `podman-compose build` | Construit ou reconstruit les services | `--no-cache`, `--pull`, `[SERVICE...]` |
| `podman-compose pull` | Télécharge les images des services | `--ignore-pull-failures`, `[SERVICE...]` |
| `podman-compose push` | Pousse les images vers un registry | `[SERVICE...]` |

### Exécution de commandes

| Commande | Description | Options courantes |
|----------|-------------|-------------------|
| `podman-compose exec` | Exécute une commande dans un service actif | `-it`, `-u`, `-e`, `SERVICE COMMAND` |
| `podman-compose run` | Exécute un service ponctuel | `--rm`, `--no-deps`, `-e`, `SERVICE [COMMAND]` |

### Configuration et validation

| Commande | Description | Options courantes |
|----------|-------------|-------------------|
| `podman-compose config` | Valide et affiche la configuration | `--services`, `--volumes`, `--resolve-image-digests` |
| `podman-compose version` | Affiche la version | - |

---

## Exemples pratiques avancés

### Exemple 1 : Variables d'environnement depuis un fichier

**Créer un fichier `.env` :**

```bash
# .env
DB_HOST=database
DB_NAME=myapp
DB_USER=app_user
DB_PASSWORD=super_secret_password
APP_ENV=production
APP_DEBUG=false
```

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  web:
    image: myapp:latest
    environment:
      - DB_HOST=${DB_HOST}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - APP_ENV=${APP_ENV}
    # Ou simplement :
    # env_file:
    #   - .env
```

**Utilisation :**

```bash
# Les variables sont automatiquement chargées depuis .env
podman-compose up -d

# Ou spécifier un autre fichier
podman-compose --env-file .env.production up -d
```

---

### Exemple 2 : Build avec arguments

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  app:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        NODE_VERSION: 18
        APP_ENV: production
    image: myapp:latest
```

**Dockerfile :**

```dockerfile
ARG NODE_VERSION=16
FROM node:${NODE_VERSION}-alpine

ARG APP_ENV=development
ENV APP_ENV=${APP_ENV}

WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .

CMD ["node", "server.js"]
```

**Utilisation :**

```bash
# Build avec les arguments définis
podman-compose build

# Forcer le rebuild
podman-compose build --no-cache
```

---

### Exemple 3 : Scaling de services

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  worker:
    image: myapp-worker:latest
    environment:
      - WORKER_ID=${HOSTNAME}
    networks:
      - app-network
    # Pas de container_name pour permettre le scaling

  redis:
    image: redis:7-alpine
    container_name: redis
    networks:
      - app-network

networks:
  app-network:
```

**Utilisation :**

```bash
# Démarrer 3 instances du worker
podman-compose up -d --scale worker=3

# Vérifier
podman-compose ps

# Scaler à 5 instances
podman-compose up -d --scale worker=5
```

---

### Exemple 4 : Profils pour différents environnements

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    profiles:
      - production
      - development

  database:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: secret
    profiles:
      - production

  database-dev:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"  # Exposé pour debug
    profiles:
      - development

  debug-tools:
    image: nicolaka/netshoot
    command: sleep infinity
    profiles:
      - development
```

**Utilisation :**

```bash
# Environnement de développement
podman-compose --profile development up -d

# Production
podman-compose --profile production up -d

# Plusieurs profils
podman-compose --profile production --profile monitoring up -d
```

---

### Exemple 5 : Healthchecks personnalisés

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  api:
    build: ./api
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 3

  database:
    image: postgres:15-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
```

**Options du healthcheck expliquées :**

- **`test`** : Commande à exécuter
  - `["CMD", ...]` : Exécution directe sans shell
  - `["CMD-SHELL", ...]` : Exécution via shell (permet pipes, ||, etc.)
- **`interval`** : Fréquence de vérification
- **`timeout`** : Temps maximum pour une vérification
- **`retries`** : Nombre d'échecs consécutifs avant "unhealthy"
- **`start_period`** : Période de grâce au démarrage (échecs ignorés)

---

### Exemple 6 : Limitations de ressources

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    deploy:
      resources:
        limits:
          cpus: '0.5'      # Max 50% d'un CPU
          memory: 512M     # Max 512 Mo RAM
        reservations:
          cpus: '0.25'     # Réserve 25% d'un CPU
          memory: 256M     # Réserve 256 Mo RAM

  database:
    image: postgres:15-alpine
    deploy:
      resources:
        limits:
          cpus: '2'        # Max 2 CPUs
          memory: 2G       # Max 2 Go RAM
```

**Note :** Avec Podman, utiliser plutôt les annotations Kubernetes ou les options de ligne de commande pour les limitations de ressources.

---

## Configuration avancée du fichier compose

### Ancres YAML pour réutilisation

```yaml
version: '3.8'

# Définition d'ancres réutilisables
x-common-variables: &common-env
  APP_ENV: production
  LOG_LEVEL: info

x-healthcheck: &default-healthcheck
  interval: 30s
  timeout: 10s
  retries: 3

services:
  web:
    image: myapp:latest
    environment:
      <<: *common-env
      SERVICE_NAME: web
    healthcheck:
      <<: *default-healthcheck
      test: ["CMD", "curl", "-f", "http://localhost/health"]

  api:
    image: myapp:latest
    environment:
      <<: *common-env
      SERVICE_NAME: api
    healthcheck:
      <<: *default-healthcheck
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
```

---

### Extension de services

```yaml
version: '3.8'

services:
  base:
    image: myapp:latest
    environment:
      APP_ENV: production
    networks:
      - app-network

  web:
    extends:
      service: base
    ports:
      - "8080:80"
    command: web

  worker:
    extends:
      service: base
    command: worker
```

---

## Validation

Vous avez réussi si vous pouvez :

- Créer un fichier `docker-compose.yml` avec plusieurs services
- Démarrer une stack avec `podman-compose up -d`
- Consulter l'état avec `podman-compose ps`
- Voir les logs avec `podman-compose logs`
- Comprendre les dépendances entre services avec `depends_on`
- Configurer des healthchecks pour vérifier la santé des services
- Créer et utiliser des volumes persistants
- Configurer des réseaux personnalisés
- Arrêter proprement avec `podman-compose down`
- Exécuter des commandes dans un service avec `podman-compose exec`

---

## Résolution de problèmes courants

### Erreur : "Service failed to start"

```bash
# Vérifier les logs du service défaillant
podman-compose logs service_name

# Vérifier la configuration
podman-compose config

# Recréer les conteneurs
podman-compose up -d --force-recreate
```

---

### Erreur : Port déjà utilisé

```bash
# Erreur : "bind: address already in use"
# Solution 1 : Changer le port hôte dans docker-compose.yml
ports:
  - "8081:80"  # Au lieu de 8080:80

# Solution 2 : Identifier et arrêter le processus
podman ps -a | grep 8080
podman stop <container_id>
```

---

### Erreur : Volume en lecture seule

```bash
# Erreur : "Read-only file system"
# Solution : Ajouter :Z pour SELinux
volumes:
  - ./data:/app/data:Z

# Ou désactiver le read-only si nécessaire
volumes:
  - ./data:/app/data:rw  # read-write (par défaut)
```

---

### Service ne démarre pas dans le bon ordre

```bash
# Problème : Le service web démarre avant que la base soit prête
# Solution : Utiliser healthcheck avec depends_on

database:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 10s
    timeout: 5s
    retries: 5

web:
  depends_on:
    database:
      condition: service_healthy
```

---

### Erreur : "Network not found"

```bash
# Recréer le réseau
podman-compose down
podman-compose up -d

# Ou manuellement
podman network create webapp-network
```

---

### Modifications du docker-compose.yml non prises en compte

```bash
# Recréer les conteneurs avec la nouvelle configuration
podman-compose up -d --force-recreate

# Ou pour rebuild les images
podman-compose up -d --build
```

---

### Nettoyer complètement une stack

```bash
# Supprimer conteneurs, réseaux et volumes
podman-compose down -v

# Supprimer aussi les images
podman-compose down -v --rmi all

# Nettoyer les ressources orphelines
podman-compose down --remove-orphans
```

---

### Vérifier la syntaxe du fichier

```bash
# Valider la configuration
podman-compose config

# Afficher la configuration résolue
podman-compose config --resolve-image-digests

# Lister uniquement les services
podman-compose config --services
```

---

## Différences Podman Compose vs Docker Compose

### Points communs
- Syntaxe identique du fichier YAML
- Commandes similaires
- Comportement équivalent pour la plupart des cas d'usage

### Différences notables

| Aspect | Podman Compose | Docker Compose |
|--------|----------------|----------------|
| **Architecture** | Sans daemon, rootless par défaut | Nécessite un daemon Docker |
| **Isolation** | Pods Kubernetes optionnels | Conteneurs simples uniquement |
| **Performance** | Démarrage légèrement plus lent | Démarrage plus rapide |
| **Sécurité** | Peut fonctionner sans root | Nécessite accès au daemon |
| **Compatibilité** | 95% compatible avec docker-compose | Standard de référence |

### Limitations de Podman Compose

- Certaines options de `deploy:` ne sont pas supportées
- `docker-compose exec` peut se comporter différemment
- Scaling limité par rapport à Docker Swarm

---

## Bonnes pratiques

### Organisation des fichiers

```
projet/
├── docker-compose.yml       # Configuration principale
├── docker-compose.override.yml  # Surcharges locales (gitignored)
├── docker-compose.prod.yml  # Configuration production
├── .env                      # Variables d'environnement (gitignored)
├── .env.example             # Template des variables
└── services/
    ├── web/
    │   ├── Dockerfile
    │   └── ...
    └── api/
        ├── Dockerfile
        └── ...
```

### Nommage

- **Services** : Noms courts et descriptifs (`web`, `api`, `database`)
- **Réseaux** : Préfixe du projet (`myapp-network`)
- **Volumes** : Descriptif (`db_data`, `redis_cache`)

### Sécurité

1. **Ne jamais committer** `.env` ou fichiers avec secrets
2. **Utiliser des secrets** pour les mots de passe sensibles
3. **Limiter les ports exposés** au strict nécessaire
4. **Utiliser des images officielles** ou vérifiées
5. **Spécifier les versions** des images (éviter `latest`)
6. **Scan de sécurité** : `podman scan image:tag`

### Performance

1. **Ordre des services** : Base de données en premier
2. **Healthchecks** : Éviter les intervalles trop courts
3. **Volumes** : Préférer les volumes nommés aux bind mounts
4. **Build cache** : Optimiser l'ordre des instructions
5. **Multi-stage builds** : Réduire la taille des images

---

## Suite

Passez au [TP4 - Systemd](../TP4-systemd/) pour apprendre à gérer vos conteneurs comme des services système avec systemd.
