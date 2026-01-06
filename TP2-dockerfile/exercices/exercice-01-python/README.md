# Exercice 1 : Créer un Dockerfile pour une application Python Flask

## 🎯 Objectifs
- Écrire votre premier Dockerfile de A à Z
- Comprendre les instructions essentielles (FROM, COPY, RUN, CMD)
- Conteneuriser une application Python Flask
- Tester votre image personnalisée

## 📚 Contexte
Vous avez une application Flask simple (fournie dans `app/`). Vous devez créer un Dockerfile pour la conteneuriser.

## 📝 Instructions

### Étape 1 : Examiner l'application
```bash
cat app/app.py
cat app/requirements.txt
```

L'application :
- Écoute sur le port **5000**
- Nécessite Flask (dans requirements.txt)
- Point d'entrée : `python app.py`

### Étape 2 : Écrire le Dockerfile
Créez un fichier `Dockerfile` avec les instructions suivantes :

1. **FROM** : Utilisez l'image de base `python:3.11-slim`
2. **WORKDIR** : Définissez `/app` comme répertoire de travail
3. **COPY** : Copiez `requirements.txt` dans le conteneur
4. **RUN** : Installez les dépendances avec `pip install -r requirements.txt`
5. **COPY** : Copiez tout le code source (`.`) dans `/app`
6. **EXPOSE** : Documentez le port 5000
7. **CMD** : Lancez l'application avec `["python", "app.py"]`

### Étape 3 : Construire l'image
```bash
podman build -t mon-app-python:v1 .
```

### Étape 4 : Tester l'image
```bash
podman run -d --name test-python -p 5000:5000 mon-app-python:v1
curl http://localhost:5000
```

## 💡 Instructions Dockerfile essentielles

```dockerfile
FROM image:tag           # Image de base
WORKDIR /chemin          # Répertoire de travail
COPY source dest         # Copier des fichiers
RUN commande             # Exécuter une commande (pendant le build)
EXPOSE port              # Documenter le port (métadonnée)
CMD ["cmd", "arg"]       # Commande par défaut (au démarrage)
```

## ✅ Critères de validation
- ✓ Le Dockerfile utilise l'image python:3.11-slim
- ✓ L'image se construit sans erreur
- ✓ Le conteneur démarre et répond sur le port 5000
- ✓ L'application retourne "Hello from Flask!"

## 🚀 À vous de jouer !
1. Créez le fichier `Dockerfile`
2. Complétez les instructions
3. Construisez : `./build.sh`
4. Validez : `./validation.sh`
