# 💡 Indices pour l'Exercice 1

Consultez ces indices progressivement. Essayez d'abord avec le niveau 1, puis passez au niveau suivant si nécessaire.

## 🎯 Étape 1 : Lancer le conteneur

### Indice Niveau 1 - Direction générale
La commande pour lancer un conteneur est `podman run`. Vous devez utiliser 3 options :
- Une pour le mode détaché
- Une pour nommer le conteneur
- Une pour mapper les ports

### Indice Niveau 2 - Structure de la commande
```bash
podman run [MODE_DÉTACHÉ] --name [NOM] -p [PORT_HOTE]:[PORT_CONTENEUR] [IMAGE]
```

Les options que vous cherchez :
- Mode détaché : commence par `-d`
- Nom du conteneur : `mon-nginx`
- Ports : `8080` (votre machine) vers `80` (conteneur)
- Image : `nginx:latest`

### Indice Niveau 3 - Commande presque complète
```bash
podman run -d --name mon-nginx -p 8080:80 nginx:latest
```

Explication de chaque partie :
- `podman run` : Crée et démarre un conteneur
- `-d` : Détaché (background), le terminal reste libre
- `--name mon-nginx` : Nomme le conteneur "mon-nginx"
- `-p 8080:80` : Mappe le port 8080 de l'hôte → port 80 du conteneur
- `nginx:latest` : Utilise l'image nginx avec le tag "latest"

---

## 🎯 Étape 2 : Vérifier le conteneur

### Indice Niveau 1 - Direction générale
Vous devez lister les conteneurs en cours d'exécution. La commande commence par `podman` et utilise deux lettres.

### Indice Niveau 2 - Structure de la commande
```bash
podman [DEUX_LETTRES]
```

Ces deux lettres sont les mêmes que la commande Unix pour voir les processus.

### Indice Niveau 3 - Commande complète
```bash
podman ps
```

`ps` signifie "Process Status" et liste tous les conteneurs en cours d'exécution.

Variantes utiles :
```bash
podman ps          # Conteneurs en cours d'exécution
podman ps -a       # TOUS les conteneurs (même arrêtés)
podman ps -q       # Seulement les IDs
```

---

## 🔍 Comprendre les options

### L'option -d (detached)
```bash
# Avec -d : le conteneur tourne en arrière-plan
podman run -d nginx
# ➜ Vous récupérez immédiatement votre terminal
# ➜ Le conteneur continue de tourner

# Sans -d : le conteneur bloque votre terminal
podman run nginx
# ➜ Votre terminal affiche les logs en direct
# ➜ Ctrl+C arrête le conteneur
```

### L'option --name
```bash
# Avec --name : vous choisissez le nom
podman run --name mon-nginx nginx
# ➜ Référencez-le par son nom : podman stop mon-nginx

# Sans --name : Podman génère un nom aléatoire
podman run nginx
# ➜ Nom généré : "festive_einstein" ou similaire
```

### L'option -p (publish)
```bash
# Format : -p PORT_HOTE:PORT_CONTENEUR
podman run -p 8080:80 nginx

# Signifie :
# localhost:8080 (votre machine)
#     ↓
#  redirige vers
#     ↓
# port 80 (conteneur nginx)
```

Exemples :
```bash
-p 8080:80     # Port 8080 de l'hôte → port 80 du conteneur
-p 3000:3000   # Port 3000 de l'hôte → port 3000 du conteneur
-p 5432:5432   # Port 5432 de l'hôte → port 5432 du conteneur (PostgreSQL)
```

---

## 🆘 Problèmes courants

### Erreur : "port is already allocated"
```
Error: cannot listen on the TCP port: listen tcp4 :8080: bind: address already in use
```

**Solution** : Un autre processus utilise déjà le port 8080
```bash
# Trouver quel processus utilise le port
sudo lsof -i :8080

# Ou changer de port
podman run -d --name mon-nginx -p 8081:80 nginx:latest
```

### Erreur : "name is already in use"
```
Error: the container name "mon-nginx" is already in use
```

**Solution** : Un conteneur avec ce nom existe déjà
```bash
# Supprimer l'ancien conteneur
podman rm -f mon-nginx

# Puis relancer votre commande
```

### Le service ne répond pas sur localhost:8080
**Vérifications** :
```bash
# 1. Le conteneur tourne-t-il ?
podman ps | grep mon-nginx

# 2. Le port est-il bien mappé ?
podman port mon-nginx

# 3. Y a-t-il des erreurs dans les logs ?
podman logs mon-nginx

# 4. Test manuel
curl http://localhost:8080
```

---

## 📚 Documentation supplémentaire

### Aide intégrée
```bash
podman run --help          # Options de la commande run
man podman-run             # Documentation complète
podman --help              # Commandes disponibles
```

### Ressources
- Cheatsheet du workshop : `../../../ressources/cheatsheet.md`
- Documentation officielle : https://docs.podman.io/en/latest/markdown/podman-run.1.html

---

## ✅ Checklist avant validation

Avant de lancer `./validation.sh`, vérifiez :

- [ ] Vous avez complété toutes les lignes avec `___`
- [ ] Vous avez exécuté `./commandes.sh` sans erreur
- [ ] La commande `podman ps` montre un conteneur "mon-nginx"
- [ ] L'URL http://localhost:8080 répond dans votre navigateur
- [ ] Vous comprenez ce que fait chaque option

---

## 🎓 Pour aller plus loin

Une fois l'exercice validé, expérimentez :

```bash
# Voir les logs en temps réel
podman logs -f mon-nginx

# Voir les statistiques d'utilisation
podman stats mon-nginx

# Inspecter la configuration complète
podman inspect mon-nginx

# Exécuter une commande dans le conteneur
podman exec mon-nginx nginx -v

# Ouvrir un shell dans le conteneur
podman exec -it mon-nginx /bin/bash
```
