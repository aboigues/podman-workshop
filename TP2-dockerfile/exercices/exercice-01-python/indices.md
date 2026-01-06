# 💡 Indices - Dockerfile Python Flask

## Solution complète

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 5000

CMD ["python", "app.py"]
```

## Explications

### FROM python:3.11-slim
- Image de base Python officielle
- Version `slim` : plus légère que la version complète

### WORKDIR /app
- Crée et définit `/app` comme répertoire de travail
- Toutes les commandes suivantes s'exécutent dans ce répertoire

### COPY app/requirements.txt .
- Copie `requirements.txt` dans `/app/`
- Le `.` représente le WORKDIR actuel

### RUN pip install --no-cache-dir -r requirements.txt
- Installe les dépendances Python
- `--no-cache-dir` : réduit la taille de l'image

### COPY app/ .
- Copie tout le code source dans `/app/`

### EXPOSE 5000
- Documente que l'application écoute sur le port 5000
- Métadonnée uniquement (ne publie pas le port)

### CMD ["python", "app.py"]
- Commande exécutée au démarrage du conteneur
- Format JSON : `["executable", "arg1", "arg2"]`
