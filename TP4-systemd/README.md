# TP4 - Automatisation avec Systemd

## Objectifs
- Comprendre l'intégration entre Podman et systemd
- Automatiser le démarrage et l'arrêt des conteneurs au boot du système
- Gérer les conteneurs comme des services système natifs
- Créer des services systemd pour conteneurs et pods
- Implémenter des politiques de redémarrage automatique
- Gérer les dépendances entre services

## Prérequis
- Podman installé
- Systemd (présent sur la plupart des distributions Linux)
- Accès terminal
- Connaissances de base sur systemd

## Démarrage rapide

```bash
# Générer un service systemd pour un conteneur
podman run -d --name nginx-demo -p 8080:80 nginx:alpine
podman generate systemd --new --files --name nginx-demo

# Installer le service en mode utilisateur
mkdir -p ~/.config/systemd/user
mv container-nginx-demo.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now container-nginx-demo.service

# Vérifier le statut
systemctl --user status container-nginx-demo.service
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
- Fichiers dans `/etc/systemd/system/`
- Nécessite les privilèges root

**Mode utilisateur (rootless)** : `systemctl --user`
- Services propres à chaque utilisateur
- Démarrage à la connexion de l'utilisateur
- Fichiers dans `~/.config/systemd/user/`
- Ne nécessite pas les privilèges root
- **Recommandé avec Podman pour la sécurité**

---

## Structure d'un fichier unit systemd

### Exemple de base

```ini
[Unit]
Description=Example Podman Container
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/podman run --name example-container nginx:alpine
ExecStop=/usr/bin/podman stop example-container
ExecStopPost=/usr/bin/podman rm -f example-container
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Explications ligne par ligne

#### Section `[Unit]`

Décrit le service et ses dépendances.

**`Description=Example Podman Container`**
- Description lisible du service
- Affichée dans les commandes `systemctl status`
- Doit être claire et concise

**`After=network-online.target`**
- Le service démarre **après** que le réseau soit en ligne
- Garantit la connectivité réseau avant le démarrage
- Important pour les conteneurs qui nécessitent l'accès réseau

**`Wants=network-online.target`**
- Dépendance "souple" sur le réseau
- Le service démarre même si le réseau n'est pas disponible
- Alternative : `Requires=` pour une dépendance "forte"

**Autres directives utiles :**
- **`Before=`** : Démarre avant un autre service
- **`Requires=`** : Dépendance forte (le service échoue si la dépendance échoue)
- **`BindsTo=`** : Comme Requires mais arrête le service si la dépendance s'arrête
- **`Conflicts=`** : Ne peut pas s'exécuter en même temps qu'un autre service

#### Section `[Service]`

Définit comment le service s'exécute.

**`Type=notify`**
- Type de service systemd
- `notify` : Le service informe systemd quand il est prêt
- Podman supporte le protocole sd_notify
- Autres types :
  - `simple` : Le processus est le service (défaut)
  - `forking` : Le service fork en arrière-plan
  - `oneshot` : Pour des tâches ponctuelles
  - `exec` : Comme simple mais attend l'exécution

**`ExecStart=/usr/bin/podman run --name example-container nginx:alpine`**
- Commande à exécuter pour démarrer le service
- Doit être un chemin absolu vers l'exécutable
- Arguments passés à la commande
- Important : Ne pas utiliser `-d` car systemd gère le daemonisation

**`ExecStop=/usr/bin/podman stop example-container`**
- Commande pour arrêter le service proprement
- Exécutée lors d'un `systemctl stop`
- Envoie SIGTERM puis SIGKILL après timeout

**`ExecStopPost=/usr/bin/podman rm -f example-container`**
- Commande exécutée **après** l'arrêt du service
- S'exécute même si le service a échoué
- Utilisée pour nettoyer les ressources
- Ici : supprime le conteneur arrêté

**`Restart=on-failure`**
- Politique de redémarrage automatique
- Options disponibles :
  - `no` : Ne jamais redémarrer (défaut)
  - `on-success` : Redémarre si le service se termine avec succès
  - `on-failure` : Redémarre en cas d'échec
  - `on-abnormal` : Redémarre si terminaison anormale (signal, timeout)
  - `on-abort` : Redémarre si terminé par un signal non traité
  - `always` : Redémarre dans tous les cas

**`RestartSec=10`**
- Délai d'attente avant de redémarrer (en secondes)
- Évite les redémarrages en boucle trop rapides
- Valeur par défaut : 100ms

**Autres directives utiles :**
- **`TimeoutStartSec=`** : Timeout pour le démarrage (défaut : 90s)
- **`TimeoutStopSec=`** : Timeout pour l'arrêt (défaut : 90s)
- **`Environment=`** : Définit des variables d'environnement
- **`WorkingDirectory=`** : Répertoire de travail

#### Section `[Install]`

Définit le comportement lors de l'activation du service.

**`WantedBy=multi-user.target`**
- Le service est "voulu" par la cible multi-user
- `multi-user.target` : Système multi-utilisateur sans interface graphique
- Le service démarre automatiquement au boot
- Pour mode utilisateur, utiliser `default.target`

**Autres targets utiles :**
- **`default.target`** : Target par défaut (mode utilisateur)
- **`graphical.target`** : Interface graphique (mode système)
- **`network-online.target`** : Réseau configuré et en ligne

---

## Génération automatique de services systemd

Podman peut générer automatiquement des fichiers unit systemd pour conteneurs et pods existants.

### Commande `podman generate systemd`

```bash
podman generate systemd [OPTIONS] CONTAINER|POD
```

### Options importantes

| Option | Description | Exemple |
|--------|-------------|---------|
| `--new` | Crée un nouveau conteneur à chaque démarrage | Recommandé |
| `--files` | Génère des fichiers au lieu d'afficher sur stdout | Obligatoire pour sauvegarder |
| `--name` | Génère le service par nom plutôt que par ID | Recommandé |
| `--time` | Délai d'attente pour l'arrêt (secondes) | `--time 30` |
| `--restart-policy` | Politique de redémarrage | `--restart-policy=always` |
| `--container-prefix` | Préfixe pour les noms de services de conteneurs | `--container-prefix=app` |
| `--pod-prefix` | Préfixe pour les noms de services de pods | `--pod-prefix=pod` |
| `--separator` | Séparateur dans les noms de fichiers | `--separator=-` |

### Différence entre `--new` et sans `--new`

**Sans `--new` (conteneur existant)**
```bash
podman run -d --name nginx-persistent -p 8080:80 nginx:alpine
podman generate systemd --files --name nginx-persistent
```

Génère :
```ini
ExecStart=/usr/bin/podman start nginx-persistent
ExecStop=/usr/bin/podman stop nginx-persistent
```

- Démarre un conteneur existant
- Le conteneur doit déjà exister
- Conserve l'état du conteneur

**Avec `--new` (création à chaque démarrage)**
```bash
podman create --name nginx-new -p 8080:80 nginx:alpine
podman generate systemd --new --files --name nginx-new
```

Génère :
```ini
ExecStartPre=/usr/bin/podman rm -f nginx-new
ExecStart=/usr/bin/podman run --name nginx-new -p 8080:80 nginx:alpine
ExecStop=/usr/bin/podman stop nginx-new
ExecStopPost=/usr/bin/podman rm -f nginx-new
```

- Crée un nouveau conteneur à chaque démarrage
- Nettoie automatiquement l'ancien conteneur
- **Recommandé** car garantit un état propre

---

## Exercices pratiques

### Exercice 1 : Service simple avec un conteneur

```bash
# 1. Créer un conteneur
podman run -d --name nginx-service -p 8080:80 nginx:alpine

# 2. Générer le fichier systemd
podman generate systemd --new --files --name nginx-service

# 3. Créer le répertoire systemd utilisateur si nécessaire
mkdir -p ~/.config/systemd/user

# 4. Déplacer le fichier généré
mv container-nginx-service.service ~/.config/systemd/user/

# 5. Recharger la configuration systemd
systemctl --user daemon-reload

# 6. Activer le service (démarrage automatique)
systemctl --user enable container-nginx-service.service

# 7. Démarrer le service
systemctl --user start container-nginx-service.service

# 8. Vérifier le statut
systemctl --user status container-nginx-service.service
```

#### Explications détaillées

**Étape 1 : Création du conteneur**
- Le conteneur est créé et démarre en mode détaché
- Cette étape sert uniquement à tester la configuration
- Le conteneur sera recréé par systemd avec `--new`

**Étape 2 : Génération du service**
- `--new` : Recrée le conteneur à chaque démarrage
- `--files` : Sauvegarde dans un fichier au lieu d'afficher
- `--name` : Utilise le nom du conteneur pour l'identification
- Génère `container-nginx-service.service`

**Étapes 3-4 : Installation**
- `~/.config/systemd/user/` : Emplacement pour les services utilisateur
- Alternative système : `/etc/systemd/system/` (nécessite root)

**Étape 5 : Rechargement**
- `daemon-reload` : Recharge la configuration systemd
- Nécessaire après toute modification de fichiers unit
- Ne redémarre pas les services existants

**Étape 6 : Activation**
- `enable` : Crée un lien symbolique dans le target approprié
- Le service démarrera automatiquement au boot/connexion
- N'affecte pas l'état actuel (démarré/arrêté)

**Étape 7 : Démarrage**
- `start` : Démarre le service immédiatement
- `enable --now` : Combine enable et start en une seule commande

**Étape 8 : Vérification**
- Affiche l'état actuel, les logs récents, et les informations du service

**Commandes supplémentaires utiles :**

```bash
# Voir les logs du service
journalctl --user -u container-nginx-service.service -f

# Redémarrer le service
systemctl --user restart container-nginx-service.service

# Arrêter le service
systemctl --user stop container-nginx-service.service

# Désactiver le démarrage automatique
systemctl --user disable container-nginx-service.service

# Voir le fichier unit
systemctl --user cat container-nginx-service.service
```

---

### Exercice 2 : Service avec volume persistant

```bash
# 1. Créer le répertoire pour le contenu
mkdir -p ~/webapp-data
echo "<h1>Hello from systemd service!</h1>" > ~/webapp-data/index.html

# 2. Créer le conteneur avec volume
podman create --name webapp-service \
    -p 8080:80 \
    -v ~/webapp-data:/usr/share/nginx/html:ro,Z \
    nginx:alpine

# 3. Générer et installer le service
podman generate systemd --new --files --name webapp-service
mv container-webapp-service.service ~/.config/systemd/user/
systemctl --user daemon-reload

# 4. Activer et démarrer
systemctl --user enable --now container-webapp-service.service

# 5. Tester
curl http://localhost:8080
```

#### Explications détaillées

**Volume avec SELinux (`:Z`)**
- `:Z` : Applique le contexte SELinux approprié
- Nécessaire sur les systèmes avec SELinux activé (Fedora, RHEL, CentOS)
- Alternative : `:z` pour un contexte partagé entre conteneurs

**Persistance des données**
- Les données dans `~/webapp-data` survivent aux redémarrages
- Modifications visibles immédiatement dans le conteneur
- Utile pour les configurations et le contenu web

---

### Exercice 3 : Pod avec plusieurs conteneurs

```bash
# 1. Créer un pod
podman pod create --name webapp-pod -p 8080:80

# 2. Ajouter un conteneur web
podman run -d --pod webapp-pod --name web nginx:alpine

# 3. Ajouter un conteneur Redis
podman run -d --pod webapp-pod --name redis redis:7-alpine

# 4. Générer les services pour le pod
podman generate systemd --new --files --name webapp-pod

# 5. Installer tous les fichiers générés
mv pod-webapp-pod.service ~/.config/systemd/user/
mv container-web.service ~/.config/systemd/user/
mv container-redis.service ~/.config/systemd/user/
systemctl --user daemon-reload

# 6. Activer et démarrer le pod
systemctl --user enable --now pod-webapp-pod.service

# 7. Vérifier tous les services
systemctl --user status pod-webapp-pod.service
systemctl --user status container-web.service
systemctl --user status container-redis.service
```

#### Explications détaillées

**Pods Podman**
- Un pod regroupe plusieurs conteneurs partageant les mêmes ressources réseau
- Similaire aux pods Kubernetes
- Tous les conteneurs du pod partagent :
  - Le namespace réseau (localhost)
  - Les ports exposés
  - Le cycle de vie (démarrage/arrêt groupé)

**Services générés**
- `pod-webapp-pod.service` : Service principal du pod
- `container-web.service` : Service du conteneur web (dépend du pod)
- `container-redis.service` : Service du conteneur redis (dépend du pod)

**Dépendances automatiques**
- Les services de conteneurs dépendent du service de pod
- Démarrer le pod démarre automatiquement tous les conteneurs
- Arrêter le pod arrête tous les conteneurs

**Communication inter-conteneurs**
- Les conteneurs communiquent via `localhost`
- Exemple : le web peut accéder à Redis via `localhost:6379`

---

### Exercice 4 : Service avec variables d'environnement

```bash
# 1. Créer le conteneur avec variables d'environnement
podman create --name db-service \
    -e POSTGRES_PASSWORD=secret123 \
    -e POSTGRES_USER=webapp \
    -e POSTGRES_DB=myapp \
    -p 5432:5432 \
    postgres:15-alpine

# 2. Générer le service
podman generate systemd --new --files --name db-service
mv container-db-service.service ~/.config/systemd/user/
systemctl --user daemon-reload

# 3. Activer et démarrer
systemctl --user enable --now container-db-service.service
```

#### Note de sécurité

⚠️ **Les variables d'environnement sont visibles dans le fichier systemd !**

Pour sécuriser les secrets, utiliser plutôt :
- Fichiers montés en volume avec permissions restreintes
- Podman secrets (à partir de Podman 3.1)
- systemd credentials (systemd 250+)

---

## Commandes systemctl essentielles

### Gestion des services

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl --user start SERVICE` | Démarre un service | `systemctl --user start container-nginx.service` |
| `systemctl --user stop SERVICE` | Arrête un service | `systemctl --user stop container-nginx.service` |
| `systemctl --user restart SERVICE` | Redémarre un service | `systemctl --user restart container-nginx.service` |
| `systemctl --user reload SERVICE` | Recharge la configuration | `systemctl --user reload container-nginx.service` |
| `systemctl --user enable SERVICE` | Active le démarrage automatique | `systemctl --user enable container-nginx.service` |
| `systemctl --user disable SERVICE` | Désactive le démarrage automatique | `systemctl --user disable container-nginx.service` |
| `systemctl --user enable --now SERVICE` | Active et démarre | `systemctl --user enable --now container-nginx.service` |

### Consultation

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl --user status SERVICE` | Affiche l'état d'un service | `systemctl --user status container-nginx.service` |
| `systemctl --user list-units` | Liste tous les services actifs | `systemctl --user list-units` |
| `systemctl --user list-unit-files` | Liste tous les fichiers unit | `systemctl --user list-unit-files` |
| `systemctl --user cat SERVICE` | Affiche le contenu du fichier unit | `systemctl --user cat container-nginx.service` |
| `systemctl --user is-active SERVICE` | Vérifie si un service est actif | `systemctl --user is-active container-nginx.service` |
| `systemctl --user is-enabled SERVICE` | Vérifie si un service est activé | `systemctl --user is-enabled container-nginx.service` |
| `systemctl --user is-failed SERVICE` | Vérifie si un service a échoué | `systemctl --user is-failed container-nginx.service` |

### Logs avec journalctl

| Commande | Description | Exemple |
|----------|-------------|---------|
| `journalctl --user -u SERVICE` | Affiche les logs d'un service | `journalctl --user -u container-nginx.service` |
| `journalctl --user -u SERVICE -f` | Logs en temps réel | `journalctl --user -u container-nginx.service -f` |
| `journalctl --user -u SERVICE --since today` | Logs depuis aujourd'hui | `journalctl --user -u container-nginx.service --since today` |
| `journalctl --user -u SERVICE --since "1 hour ago"` | Logs de la dernière heure | `journalctl --user -u container-nginx.service --since "1 hour ago"` |
| `journalctl --user -u SERVICE -n 50` | 50 dernières lignes | `journalctl --user -u container-nginx.service -n 50` |
| `journalctl --user -u SERVICE --no-pager` | Sans pagination | `journalctl --user -u container-nginx.service --no-pager` |

### Gestion de systemd

| Commande | Description |
|----------|-------------|
| `systemctl --user daemon-reload` | Recharge la configuration systemd |
| `systemctl --user reset-failed` | Réinitialise l'état "failed" de tous les services |
| `systemctl --user show SERVICE` | Affiche toutes les propriétés d'un service |
| `systemctl --user edit SERVICE` | Édite un service (override) |

---

## Exemples pratiques avancés

### Exemple 1 : Service avec healthcheck

Créer un script de healthcheck :

```bash
#!/bin/bash
# ~/scripts/healthcheck-nginx.sh

curl -f http://localhost:8080 > /dev/null 2>&1
exit $?
```

Service systemd avec healthcheck :

```ini
[Unit]
Description=Nginx Container with Healthcheck
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStartPre=/usr/bin/podman rm -f nginx-health
ExecStart=/usr/bin/podman run --name nginx-health -p 8080:80 nginx:alpine
ExecStop=/usr/bin/podman stop nginx-health
ExecStopPost=/usr/bin/podman rm -f nginx-health
Restart=on-failure
RestartSec=10

# Healthcheck toutes les 30 secondes
ExecStartPost=/bin/bash -c 'while true; do sleep 30; ~/scripts/healthcheck-nginx.sh || systemctl --user restart %n; done'

[Install]
WantedBy=default.target
```

---

### Exemple 2 : Démarrage conditionnel basé sur le réseau

Service qui ne démarre que si une interface réseau spécifique est active :

```ini
[Unit]
Description=Container requiring specific network
After=network-online.target
Wants=network-online.target
# Attend que eth0 soit active
ConditionPathExists=/sys/class/net/eth0/operstate

[Service]
Type=notify
ExecStart=/usr/bin/podman run --name network-dependent nginx:alpine
ExecStop=/usr/bin/podman stop network-dependent
ExecStopPost=/usr/bin/podman rm -f network-dependent
Restart=on-failure

[Install]
WantedBy=default.target
```

---

### Exemple 3 : Service avec dépendances entre conteneurs

**Service de base de données** (`~/.config/systemd/user/container-database.service`)

```ini
[Unit]
Description=PostgreSQL Database Container
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStartPre=/usr/bin/podman rm -f database
ExecStart=/usr/bin/podman run \
    --name database \
    -e POSTGRES_PASSWORD=secret \
    -v db_data:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:15-alpine
ExecStop=/usr/bin/podman stop database
ExecStopPost=/usr/bin/podman rm -f database
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

**Service web dépendant de la base** (`~/.config/systemd/user/container-webapp.service`)

```ini
[Unit]
Description=Web Application Container
After=network-online.target container-database.service
Wants=network-online.target
Requires=container-database.service

[Service]
Type=notify
ExecStartPre=/usr/bin/podman rm -f webapp
ExecStart=/usr/bin/podman run \
    --name webapp \
    -e DB_HOST=localhost \
    -e DB_PORT=5432 \
    -p 8080:80 \
    myapp:latest
ExecStop=/usr/bin/podman stop webapp
ExecStopPost=/usr/bin/podman rm -f webapp
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

**Installation :**

```bash
systemctl --user daemon-reload
systemctl --user enable --now container-database.service container-webapp.service
```

---

### Exemple 4 : Service avec timer systemd

Pour exécuter périodiquement un conteneur (alternative à cron) :

**Service** (`~/.config/systemd/user/backup-container.service`)

```ini
[Unit]
Description=Backup Container

[Service]
Type=oneshot
ExecStart=/usr/bin/podman run --rm \
    -v /home/user/data:/data:ro \
    -v /home/user/backups:/backups \
    backup-image:latest
```

**Timer** (`~/.config/systemd/user/backup-container.timer`)

```ini
[Unit]
Description=Run backup container daily

[Timer]
# Exécute tous les jours à 2h du matin
OnCalendar=daily
OnCalendar=02:00
# Rattrape l'exécution si le système était éteint
Persistent=true

[Install]
WantedBy=timers.target
```

**Activation :**

```bash
systemctl --user daemon-reload
systemctl --user enable --now backup-container.timer

# Vérifier le timer
systemctl --user list-timers
```

---

### Exemple 5 : Service avec socket activation

Socket activation permet de démarrer un service uniquement quand une connexion est tentée :

**Socket** (`~/.config/systemd/user/container-app.socket`)

```ini
[Unit]
Description=Container App Socket

[Socket]
ListenStream=8080

[Install]
WantedBy=sockets.target
```

**Service** (`~/.config/systemd/user/container-app.service`)

```ini
[Unit]
Description=Container App
Requires=container-app.socket

[Service]
Type=notify
ExecStart=/usr/bin/podman run --name app myapp:latest
ExecStop=/usr/bin/podman stop app
ExecStopPost=/usr/bin/podman rm -f app
```

**Activation :**

```bash
systemctl --user enable --now container-app.socket
# Le service démarre automatiquement lors de la première connexion sur le port 8080
```

---

### Exemple 6 : Service avec ressources limitées

```ini
[Unit]
Description=Container with Resource Limits

[Service]
Type=notify
ExecStart=/usr/bin/podman run \
    --name limited-app \
    --memory=512m \
    --cpus=1.0 \
    --pids-limit=100 \
    myapp:latest
ExecStop=/usr/bin/podman stop limited-app
ExecStopPost=/usr/bin/podman rm -f limited-app
Restart=on-failure

# Limites systemd additionnelles
MemoryMax=512M
CPUQuota=100%
TasksMax=100

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

# Désactiver
loginctl disable-linger
```

### Conversion d'un service utilisateur en service système

**Service utilisateur** (`~/.config/systemd/user/myservice.service`)

```bash
# Arrêter et désactiver le service utilisateur
systemctl --user stop myservice.service
systemctl --user disable myservice.service

# Copier vers le système
sudo cp ~/.config/systemd/user/myservice.service /etc/systemd/system/

# Éditer pour ajuster les chemins si nécessaire
sudo systemctl edit myservice.service

# Activer comme service système
sudo systemctl daemon-reload
sudo systemctl enable --now myservice.service
```

---

## Validation

Vous avez réussi si vous pouvez :

- Générer un fichier systemd unit avec `podman generate systemd`
- Comprendre la structure d'un fichier unit (sections Unit, Service, Install)
- Installer un service en mode utilisateur dans `~/.config/systemd/user/`
- Utiliser `systemctl --user` pour gérer les services
- Activer le démarrage automatique avec `enable`
- Consulter les logs avec `journalctl --user`
- Créer des dépendances entre services avec `Requires=` et `After=`
- Configurer des politiques de redémarrage avec `Restart=`
- Gérer des pods multi-conteneurs avec systemd
- Activer le linger pour maintenir les services après déconnexion

---

## Résolution de problèmes courants

### Service n'arrive pas à démarrer

```bash
# Vérifier l'état détaillé
systemctl --user status container-myapp.service

# Voir les logs complets
journalctl --user -u container-myapp.service -n 100 --no-pager

# Vérifier la syntaxe du fichier unit
systemd-analyze verify ~/.config/systemd/user/container-myapp.service

# Tester la commande ExecStart manuellement
/usr/bin/podman run --name myapp myimage:latest
```

**Causes fréquentes :**
- Chemin absolu manquant dans ExecStart
- Port déjà utilisé
- Image non disponible localement
- Permissions insuffisantes

---

### Service s'arrête après la déconnexion

```bash
# Problème : Les services utilisateur s'arrêtent à la déconnexion
# Solution : Activer le linger

loginctl enable-linger $USER

# Vérifier
loginctl show-user $USER | grep Linger
# Devrait afficher : Linger=yes
```

---

### Le conteneur existe déjà (erreur avec --new)

```bash
# Erreur : "container already exists"
# Cause : Un conteneur avec ce nom existe déjà

# Solution 1 : Supprimer le conteneur existant
podman rm -f mycontainer

# Solution 2 : Forcer la recréation dans le service
# Le fichier généré avec --new devrait déjà inclure :
# ExecStartPre=/usr/bin/podman rm -f mycontainer

# Vérifier le fichier unit
systemctl --user cat container-mycontainer.service | grep ExecStartPre
```

---

### Service en état "failed"

```bash
# Voir pourquoi le service a échoué
systemctl --user status container-myapp.service
journalctl --user -u container-myapp.service --since "5 minutes ago"

# Réinitialiser l'état failed
systemctl --user reset-failed container-myapp.service

# Redémarrer
systemctl --user start container-myapp.service
```

---

### Modifications du fichier unit non prises en compte

```bash
# Après toute modification d'un fichier unit, recharger systemd
systemctl --user daemon-reload

# Puis redémarrer le service
systemctl --user restart container-myapp.service

# Vérifier que les modifications sont bien prises en compte
systemctl --user cat container-myapp.service
```

---

### Service redémarre en boucle

```bash
# Vérifier les logs pour identifier la cause
journalctl --user -u container-myapp.service -f

# Désactiver temporairement pour investigation
systemctl --user stop container-myapp.service
systemctl --user disable container-myapp.service

# Tester manuellement le conteneur
podman run --name myapp-test myimage:latest

# Solutions possibles :
# 1. Augmenter RestartSec pour éviter les boucles rapides
# 2. Changer la politique de Restart=on-failure
# 3. Corriger la configuration du conteneur
```

---

### Permissions refusées avec volumes

```bash
# Erreur : Permission denied lors de l'accès à un volume
# Solution : Ajouter :Z pour le contexte SELinux

# Mauvais
-v /home/user/data:/data

# Bon
-v /home/user/data:/data:Z

# Régénérer le service après correction
podman stop mycontainer
podman rm mycontainer
podman create --name mycontainer -v /home/user/data:/data:Z myimage:latest
podman generate systemd --new --files --name mycontainer
```

---

### Dépendances circulaires

```bash
# Erreur : "Found ordering cycle"
# Cause : Service A dépend de B qui dépend de A

# Vérifier les dépendances
systemctl --user list-dependencies container-app1.service
systemctl --user list-dependencies container-app2.service

# Solution : Retirer les dépendances circulaires
# Éditer les fichiers et supprimer les lignes problématiques
systemctl --user edit container-app1.service

# Recharger
systemctl --user daemon-reload
```

---

### Nettoyer tous les services Podman

```bash
# Lister tous les services de conteneurs
systemctl --user list-units "container-*.service" --all

# Arrêter et désactiver tous
systemctl --user list-units "container-*.service" --all --no-legend | \
    awk '{print $1}' | \
    xargs -r systemctl --user disable --now

# Supprimer les fichiers
rm ~/.config/systemd/user/container-*.service
rm ~/.config/systemd/user/pod-*.service

# Recharger
systemctl --user daemon-reload

# Réinitialiser les états failed
systemctl --user reset-failed
```

---

## Bonnes pratiques

### Nommage des services

- **Préfixe cohérent** : Utiliser un préfixe pour grouper les services (`app-web.service`, `app-db.service`)
- **Descriptif** : Noms clairs et explicites
- **Éviter les caractères spéciaux** : Utiliser lettres, chiffres, tirets et underscores uniquement

### Organisation des fichiers

```
~/.config/systemd/user/
├── container-web.service
├── container-db.service
├── pod-myapp.service
└── backups/
    └── container-web.service.backup
```

### Sécurité

1. **Mode utilisateur par défaut** : Privilégier `systemctl --user` sauf besoin spécifique
2. **Pas de secrets dans les fichiers unit** : Utiliser des volumes ou secrets Podman
3. **Permissions strictes** : `chmod 600` sur les fichiers contenant des informations sensibles
4. **Limites de ressources** : Toujours définir des limites pour éviter la surcharge système
5. **SELinux** : Utiliser `:Z` ou `:z` sur les volumes avec SELinux activé

### Performance

1. **RestartSec approprié** : Éviter les redémarrages trop rapides (minimum 5-10s)
2. **TimeoutStartSec raisonnable** : Adapter au temps de démarrage réel de l'application
3. **Type=notify** : Préférer pour Podman car plus précis que `simple`
4. **Dépendances minimales** : N'ajouter que les dépendances nécessaires

### Maintenance

1. **Documenter les services** : Utiliser `Description=` de manière détaillée
2. **Versionner les fichiers unit** : Les inclure dans le contrôle de version
3. **Scripts de déploiement** : Automatiser l'installation des services
4. **Monitoring** : Surveiller régulièrement avec `systemctl status` et `journalctl`
5. **Sauvegardes** : Sauvegarder `~/.config/systemd/user/` régulièrement

### Logs

```bash
# Activer la rotation des logs pour éviter la saturation
sudo journalctl --vacuum-time=7d  # Garder 7 jours
sudo journalctl --vacuum-size=500M  # Limiter à 500 Mo

# Configuration persistante dans /etc/systemd/journald.conf
SystemMaxUse=500M
MaxRetentionSec=7day
```

---

## Scripts utiles

### Script de génération de service

Créer `~/scripts/create-podman-service.sh` :

```bash
#!/bin/bash
set -e

CONTAINER_NAME=${1:?Usage: $0 CONTAINER_NAME}

echo "Generating systemd service for $CONTAINER_NAME..."

# Générer le service
podman generate systemd --new --files --name "$CONTAINER_NAME"

# Créer le répertoire systemd si nécessaire
mkdir -p ~/.config/systemd/user

# Déplacer le fichier
mv "container-${CONTAINER_NAME}.service" ~/.config/systemd/user/

# Recharger systemd
systemctl --user daemon-reload

echo "✓ Service created: container-${CONTAINER_NAME}.service"
echo ""
echo "Next steps:"
echo "  systemctl --user enable container-${CONTAINER_NAME}.service"
echo "  systemctl --user start container-${CONTAINER_NAME}.service"
```

**Utilisation :**

```bash
chmod +x ~/scripts/create-podman-service.sh
~/scripts/create-podman-service.sh nginx-service
```

---

### Script de monitoring des services

Créer `~/scripts/monitor-services.sh` :

```bash
#!/bin/bash

echo "=== Podman Services Status ==="
echo ""

systemctl --user list-units "container-*.service" "pod-*.service" \
    --no-legend --all | \
    while read unit load active sub desc; do
        if [ "$active" = "active" ]; then
            status="✓"
        elif [ "$active" = "failed" ]; then
            status="✗"
        else
            status="○"
        fi
        printf "%s %-40s %s\n" "$status" "$unit" "$sub"
    done

echo ""
echo "Legend: ✓ active  ✗ failed  ○ inactive"
```

---

## Suite

Passez au [TP5A - Sécurité](../TP5A-securite/) pour apprendre à sécuriser vos conteneurs Podman avec les meilleures pratiques de sécurité.
