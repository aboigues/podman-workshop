# TP1 - Création d'un conteneur simple

## Objectifs
- Lancer un conteneur avec Podman
- Comprendre les états d'un conteneur
- Gérer l'arrêt et la suppression
- Explorer les logs

## Prérequis
- Podman installé
- Accès terminal
- Connexion internet

## Démarrage rapide
```bash
# Test rapide
./exercices/quick-test.sh

# Demo complète
./exercices/demo-complete.sh

# Solutions
cat solutions/exercice1-solution.sh
```

---

## Exercices

### Exercice 1 : Premier conteneur

```bash
podman run -d --name mon-nginx -p 8080:80 nginx:latest
podman ps
curl http://localhost:8080
```

#### Explications détaillées

**`podman run -d --name mon-nginx -p 8080:80 nginx:latest`**

- **`podman run`** : Crée et démarre un nouveau conteneur
- **`-d`** (detached) : Exécute le conteneur en arrière-plan et affiche uniquement l'ID du conteneur
- **`--name mon-nginx`** : Assigne un nom personnalisé au conteneur (facilite sa gestion ultérieure)
- **`-p 8080:80`** (publish) : Mappe le port du conteneur vers l'hôte
  - Format : `PORT_HOTE:PORT_CONTENEUR`
  - Ici : le port 80 du conteneur est accessible via le port 8080 de l'hôte
- **`nginx:latest`** : Spécifie l'image à utiliser
  - Format : `NOM_IMAGE:TAG`
  - `latest` télécharge la version la plus récente

**`podman ps`**

- Affiche la liste des conteneurs en cours d'exécution
- Colonnes affichées :
  - **CONTAINER ID** : Identifiant unique court
  - **IMAGE** : Image source utilisée
  - **COMMAND** : Commande lancée au démarrage
  - **CREATED** : Date/heure de création
  - **STATUS** : État actuel (Up depuis X temps)
  - **PORTS** : Mappages de ports configurés
  - **NAMES** : Nom(s) du conteneur

**`curl http://localhost:8080`**

- Envoie une requête HTTP GET pour tester l'accès au serveur nginx
- Devrait retourner la page HTML par défaut de nginx

---

### Exercice 2 : Consultation des logs

```bash
podman logs mon-nginx
podman logs -f mon-nginx
podman logs --tail 10 mon-nginx
```

#### Explications détaillées

**`podman logs mon-nginx`**

- Affiche tous les logs générés par le conteneur depuis son démarrage
- Récupère la sortie standard (stdout) et les erreurs (stderr)

**`podman logs -f mon-nginx`**

- **`-f`** (follow) : Mode suivi en temps réel
- Reste connecté et affiche les nouveaux logs au fur et à mesure
- Similaire à `tail -f` sur un fichier
- Interrompre avec `Ctrl+C`

**`podman logs --tail 10 mon-nginx`**

- **`--tail 10`** : Affiche uniquement les 10 dernières lignes de logs
- Utile pour vérifier rapidement l'état récent sans tout afficher
- Peut être combiné avec `-f` : `podman logs --tail 10 -f mon-nginx`

**Options supplémentaires utiles :**
- **`--since`** : Affiche les logs depuis un moment donné (ex: `--since 5m` pour les 5 dernières minutes)
- **`--until`** : Affiche les logs jusqu'à un moment donné
- **`-t`** (timestamps) : Ajoute l'horodatage à chaque ligne

---

### Exercice 3 : Cycle de vie d'un conteneur

```bash
podman stop mon-nginx
podman ps -a
podman start mon-nginx
podman rm -f mon-nginx
```

#### Explications détaillées

**`podman stop mon-nginx`**

- Arrête un conteneur en cours d'exécution de manière propre
- Envoie d'abord un signal SIGTERM au processus principal
- Attend 10 secondes par défaut pour un arrêt gracieux
- Envoie ensuite SIGKILL si le processus ne s'est pas arrêté
- Options utiles :
  - **`-t`** ou **`--time`** : Modifie le délai d'attente (ex: `-t 30` pour 30 secondes)

**`podman ps -a`**

- **`-a`** (all) : Affiche TOUS les conteneurs, y compris ceux arrêtés
- Colonne **STATUS** montre :
  - `Up X minutes` : En cours d'exécution
  - `Exited (0) X minutes ago` : Arrêté (code 0 = arrêt normal)
  - `Exited (137) X minutes ago` : Arrêté de force (code 137 = SIGKILL)

**`podman start mon-nginx`**

- Démarre un conteneur existant qui a été arrêté
- Conserve toutes les configurations initiales (ports, volumes, etc.)
- Ne crée PAS un nouveau conteneur (contrairement à `podman run`)
- Options :
  - **`-a`** (attach) : Attache la console au conteneur
  - **`-i`** (interactive) : Mode interactif

**`podman rm -f mon-nginx`**

- **`podman rm`** : Supprime un ou plusieurs conteneurs
- **`-f`** (force) : Force la suppression même si le conteneur est en cours d'exécution
  - Équivaut à faire `podman stop` puis `podman rm`
- Sans `-f`, la commande échoue si le conteneur est actif
- Options supplémentaires :
  - **`-v`** (volumes) : Supprime aussi les volumes anonymes associés
  - **`-a`** : Supprime tous les conteneurs arrêtés

---

### Exercice 4 : Mode interactif

```bash
podman run -it --name mon-ubuntu ubuntu:latest /bin/bash
# Dans le conteneur :
whoami
ls -la
exit
```

#### Explications détaillées

**`podman run -it --name mon-ubuntu ubuntu:latest /bin/bash`**

- **`-i`** (interactive) : Garde STDIN ouvert même sans attachement
  - Permet d'envoyer des commandes au conteneur
- **`-t`** (tty) : Alloue un pseudo-terminal (TTY)
  - Simule un terminal complet avec formatage, couleurs, etc.
- **`-it`** : Combinaison des deux, nécessaire pour une session shell interactive
- **`--name mon-ubuntu`** : Nomme le conteneur pour faciliter sa gestion
- **`ubuntu:latest`** : Image Ubuntu la plus récente
- **`/bin/bash`** : Commande à exécuter au démarrage
  - Remplace la commande par défaut de l'image
  - Lance un shell bash interactif

**Commandes dans le conteneur :**

**`whoami`**
- Affiche l'utilisateur actuel (généralement `root` dans un conteneur)

**`ls -la`**
- Liste tous les fichiers et répertoires (y compris cachés) avec détails
- **`-l`** : Format long (permissions, propriétaire, taille, date)
- **`-a`** : Inclut les fichiers cachés (commençant par `.`)

**`exit`**
- Quitte le shell bash
- Arrête le conteneur car bash était le processus principal (PID 1)
- Alternative : `Ctrl+D`

**Note importante :** Pour se détacher d'un conteneur sans l'arrêter, utiliser `Ctrl+P` puis `Ctrl+Q`

---

## Commandes essentielles - Référence complète

### Création et démarrage

| Commande | Description | Syntaxe | Options courantes |
|----------|-------------|---------|-------------------|
| `podman run` | Crée et démarre un conteneur | `podman run [OPTIONS] IMAGE [COMMAND] [ARG...]` | `-d`, `-it`, `--name`, `-p`, `-v`, `--rm`, `-e` |
| `podman create` | Crée un conteneur sans le démarrer | `podman create [OPTIONS] IMAGE [COMMAND]` | Mêmes options que `run` |
| `podman start` | Démarre un conteneur arrêté | `podman start [OPTIONS] CONTAINER` | `-a`, `-i` |

### Gestion de l'état

| Commande | Description | Syntaxe | Options courantes |
|----------|-------------|---------|-------------------|
| `podman stop` | Arrête un conteneur proprement | `podman stop [OPTIONS] CONTAINER` | `-t`, `--time` |
| `podman restart` | Redémarre un conteneur | `podman restart [OPTIONS] CONTAINER` | `-t`, `--time` |
| `podman pause` | Met en pause tous les processus | `podman pause CONTAINER` | - |
| `podman unpause` | Reprend l'exécution | `podman unpause CONTAINER` | - |
| `podman kill` | Arrête immédiatement (SIGKILL) | `podman kill [OPTIONS] CONTAINER` | `-s`, `--signal` |

### Consultation

| Commande | Description | Syntaxe | Options courantes |
|----------|-------------|---------|-------------------|
| `podman ps` | Liste les conteneurs actifs | `podman ps [OPTIONS]` | `-a`, `-q`, `--format`, `--filter` |
| `podman logs` | Affiche les logs | `podman logs [OPTIONS] CONTAINER` | `-f`, `--tail`, `--since`, `-t` |
| `podman inspect` | Affiche les détails complets | `podman inspect [OPTIONS] CONTAINER` | `--format`, `--type` |
| `podman top` | Affiche les processus en cours | `podman top CONTAINER [ps OPTIONS]` | - |
| `podman stats` | Affiche les statistiques en temps réel | `podman stats [OPTIONS] [CONTAINER...]` | `--no-stream`, `--format` |

### Exécution

| Commande | Description | Syntaxe | Options courantes |
|----------|-------------|---------|-------------------|
| `podman exec` | Exécute une commande dans un conteneur actif | `podman exec [OPTIONS] CONTAINER COMMAND [ARG...]` | `-it`, `-d`, `-e`, `-u` |
| `podman attach` | Attache la console à un conteneur actif | `podman attach [OPTIONS] CONTAINER` | `--no-stdin`, `--sig-proxy` |

### Suppression

| Commande | Description | Syntaxe | Options courantes |
|----------|-------------|---------|-------------------|
| `podman rm` | Supprime un ou plusieurs conteneurs | `podman rm [OPTIONS] CONTAINER` | `-f`, `-v`, `-a` |
| `podman prune` | Supprime tous les conteneurs arrêtés | `podman container prune [OPTIONS]` | `-f`, `--filter` |

---

## Options les plus utilisées

### Options de `podman run`

**Exécution en arrière-plan :**
- **`-d`**, **`--detach`** : Lance en arrière-plan

**Nommage :**
- **`--name`** : Assigne un nom au conteneur

**Mode interactif :**
- **`-i`**, **`--interactive`** : Garde STDIN ouvert
- **`-t`**, **`--tty`** : Alloue un pseudo-terminal

**Réseau et ports :**
- **`-p`**, **`--publish`** : Mappe un port (format : `HOTE:CONTENEUR`)
- **`-P`**, **`--publish-all`** : Publie tous les ports exposés vers des ports aléatoires
- **`--network`** : Spécifie le réseau à utiliser

**Volumes et stockage :**
- **`-v`**, **`--volume`** : Monte un volume (format : `SOURCE:DESTINATION`)
- **`--mount`** : Syntaxe plus explicite pour monter des volumes

**Variables d'environnement :**
- **`-e`**, **`--env`** : Définit une variable d'environnement (format : `CLE=VALEUR`)
- **`--env-file`** : Charge les variables depuis un fichier

**Nettoyage automatique :**
- **`--rm`** : Supprime automatiquement le conteneur à son arrêt

**Utilisateur :**
- **`-u`**, **`--user`** : Spécifie l'utilisateur (format : `UID` ou `UID:GID`)

**Ressources :**
- **`--memory`** : Limite la mémoire (ex : `512m`, `2g`)
- **`--cpus`** : Limite les CPUs (ex : `1.5`)

---

## Exemples pratiques avancés

### Exemple 1 : Conteneur avec variables d'environnement
```bash
podman run -d \
  --name db-postgres \
  -e POSTGRES_PASSWORD=motdepasse \
  -e POSTGRES_USER=admin \
  -e POSTGRES_DB=mabase \
  -p 5432:5432 \
  postgres:15
```

### Exemple 2 : Conteneur avec volume persistant
```bash
podman run -d \
  --name web-data \
  -v /chemin/hote/data:/usr/share/nginx/html:Z \
  -p 8080:80 \
  nginx:latest
```

### Exemple 3 : Suppression automatique après utilisation
```bash
podman run --rm -it ubuntu:latest /bin/bash
# Le conteneur sera automatiquement supprimé après avoir tapé 'exit'
```

### Exemple 4 : Exécuter une commande dans un conteneur actif
```bash
# Lancer un shell interactif dans un conteneur en cours
podman exec -it mon-nginx /bin/bash

# Exécuter une commande unique
podman exec mon-nginx nginx -t
```

### Exemple 5 : Redémarrage automatique
```bash
podman run -d \
  --name mon-service \
  --restart=always \
  nginx:latest
```

---

## Validation

Vous avez réussi si vous pouvez :

- Lancer un conteneur en arrière-plan avec `podman run -d`
- Consulter ses logs avec `podman logs` et en mode suivi avec `-f`
- Arrêter et redémarrer un conteneur avec `podman stop` et `podman start`
- Lister les conteneurs actifs et arrêtés avec `podman ps` et `podman ps -a`
- Exécuter des commandes dans un conteneur actif avec `podman exec`
- Utiliser le mode interactif avec `podman run -it`
- Supprimer proprement un conteneur avec `podman rm`

---

## Résolution de problèmes courants

### Le port est déjà utilisé
```bash
# Erreur : bind: address already in use
# Solution : Utiliser un autre port hôte
podman run -d --name mon-nginx -p 8081:80 nginx:latest
```

### Le conteneur s'arrête immédiatement
```bash
# Vérifier les logs pour voir l'erreur
podman logs mon-conteneur

# Vérifier le code de sortie
podman ps -a --filter "name=mon-conteneur"
```

### Permission refusée sur un volume
```bash
# Ajouter :Z pour le contexte SELinux
podman run -d -v /chemin/hote:/chemin/conteneur:Z nginx:latest
```

### Nettoyer tous les conteneurs arrêtés
```bash
podman container prune -f
```

---

## Suite

Passez au [TP2 - Dockerfile](../TP2-dockerfile/) pour apprendre à créer vos propres images personnalisées.

