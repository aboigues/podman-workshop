# Exercice 1 : Stack Web + Base de données

## 🎯 Objectifs
- Écrire votre premier fichier compose.yaml
- Orchestrer plusieurs conteneurs
- Configurer des réseaux et volumes
- Gérer les dépendances entre services

## 📚 Contexte
Vous allez créer une stack avec :
- Un serveur web (nginx)
- Une base de données (PostgreSQL)
- Un réseau personnalisé
- Un volume pour la persistance

## 📝 Instructions

Créez un fichier `compose.yaml` avec la structure suivante :

```yaml
version: '3.8'

services:
  # Service web
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    networks:
      - app-network
    depends_on:
      - db

  # Service base de données
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: ___          # Nom de la BDD
      POSTGRES_USER: ___        # Utilisateur
      POSTGRES_PASSWORD: ___    # Mot de passe
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

# Définition des réseaux
networks:
  app-network:
    driver: bridge

# Définition des volumes
volumes:
  db-data:
```

## 🚀 Commandes

```bash
# Démarrer la stack
podman-compose up -d

# Voir les services
podman-compose ps

# Logs
podman-compose logs

# Arrêter
podman-compose down

# Arrêter et supprimer les volumes
podman-compose down -v
```

## ✅ Validation

```bash
./validation.sh
```

## 💡 Concepts clés

- **services** : Définit vos conteneurs
- **networks** : Réseau pour la communication inter-conteneurs
- **volumes** : Persistance des données
- **depends_on** : Ordre de démarrage
- **environment** : Variables d'environnement
