# Exercice 1 : Créer et lancer votre premier conteneur

## 🎯 Objectifs
- Lancer un conteneur en mode détaché
- Comprendre les options de base de `podman run`
- Vérifier qu'un conteneur est en cours d'exécution
- Tester l'accès à un service web conteneurisé

## 📚 Contexte
Vous allez lancer votre premier conteneur Podman ! Nous utiliserons l'image **nginx** qui est un serveur web populaire. L'objectif est de :
1. Démarrer un conteneur nginx en arrière-plan
2. Le nommer pour pouvoir le référencer facilement
3. Exposer le port 80 du conteneur sur le port 8080 de votre machine
4. Vérifier que le serveur web répond

## 📝 Instructions

### Étape 1 : Lancer le conteneur
Créez un conteneur nginx qui :
- S'exécute en **mode détaché** (arrière-plan)
- Se nomme **mon-nginx**
- Mappe le **port 8080** de votre machine vers le **port 80** du conteneur
- Utilise l'image **nginx:latest**

### Étape 2 : Vérifier le conteneur
Listez les conteneurs en cours d'exécution pour confirmer que votre conteneur fonctionne.

### Étape 3 : Tester le service
Testez que le serveur nginx répond en accédant à http://localhost:8080

## 💡 Concepts clés à comprendre

### Mode détaché (-d)
```
-d ou --detach : Le conteneur s'exécute en arrière-plan
Sans -d : Le conteneur s'exécute au premier plan et bloque votre terminal
```

### Nommage des conteneurs (--name)
```
--name mon-nom : Donne un nom personnalisé au conteneur
Sans --name : Podman génère un nom aléatoire (ex: jolly_einstein)
```

### Mappage de ports (-p)
```
-p PORT_HOTE:PORT_CONTENEUR
-p 8080:80 signifie :
  - localhost:8080 sur votre machine
  → redirige vers port 80 du conteneur
```

### Format d'image
```
IMAGE:TAG
nginx:latest → image "nginx" avec le tag "latest"
```

## ✅ Critères de validation

Votre exercice sera validé si :
- ✓ Un conteneur nommé 'mon-nginx' existe
- ✓ Ce conteneur est en cours d'exécution (état: running)
- ✓ Le port 8080 est correctement mappé au port 80 du conteneur
- ✓ Le service HTTP répond avec le code 200 sur http://localhost:8080

## 🚀 À vous de jouer !

1. Ouvrez le fichier `commandes.sh`
2. Complétez les commandes manquantes (remplacez les `___`)
3. Exécutez vos commandes : `./commandes.sh`
4. Validez votre travail : `./validation.sh`

Si vous êtes bloqué, consultez `indices.md` !

## 📖 Commandes utiles

```bash
# Aide sur la commande run
podman run --help

# Documentation complète
man podman-run

# Lister les conteneurs en cours d'exécution
podman ps

# Lister TOUS les conteneurs (même arrêtés)
podman ps -a
```

## 🎓 Ce que vous allez apprendre
Après cet exercice, vous saurez :
- ✅ Lancer un conteneur en arrière-plan
- ✅ Nommer un conteneur
- ✅ Exposer des ports
- ✅ Vérifier l'état d'un conteneur
- ✅ Tester un service conteneurisé
