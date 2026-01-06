# Exercice 4 : Mode interactif et exécution de commandes

## 🎯 Objectifs
- Lancer un conteneur en mode interactif
- Exécuter des commandes dans un conteneur en cours d'exécution
- Comprendre la différence entre `run` et `exec`

## 📝 Instructions

### Étape 1 : Lancer un conteneur interactif
Lancez un conteneur **alpine** en mode interactif avec un shell bash.
Options : `-it` (interactive + tty) et commande `/bin/sh`.

### Étape 2 : Explorer le conteneur (manuel)
Une fois dans le conteneur, tapez quelques commandes pour explorer :
- `whoami` - Voir l'utilisateur
- `pwd` - Voir le répertoire courant
- `ls /` - Lister les fichiers
- `exit` - Sortir du conteneur

### Étape 3 : Exécuter une commande dans un conteneur existant
Créez un conteneur nginx nommé **exec-test**, puis utilisez `podman exec` pour exécuter une commande dedans.

## 💡 Concepts clés

```bash
# Mode interactif (lance un nouveau conteneur)
podman run -it IMAGE COMMANDE

# Exécuter dans un conteneur existant
podman exec CONTENEUR COMMANDE
podman exec -it CONTENEUR /bin/bash  # Shell interactif
```

### Différence run vs exec
- **run** : Crée ET démarre un nouveau conteneur
- **exec** : Exécute une commande dans un conteneur EXISTANT

## 🚀 À vous de jouer !
1. Ouvrez `commandes.sh`
2. Complétez les commandes
3. Exécutez : `./commandes.sh`
