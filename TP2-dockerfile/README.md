# TP2 - Creation de Dockerfile et images personnalisees

## Objectifs
- Comprendre la structure d'un Dockerfile
- Creer des images personnalisees
- Optimiser la taille des images
- Utiliser les builds multi-stage

## Exemples inclus

Tous les exemples sont fonctionnels et testes :

- `python-app/` - Application Flask avec API
- `go-app/` - Application Go avec multi-stage
- `nginx-custom/` - Serveur web personnalise

## Quick Start

```bash
# Tester tous les exemples
./test-all-examples.sh

# Python
cd python-app
podman build -t my-python-app .
podman run -d -p 5000:5000 my-python-app
curl http://localhost:5000

# Go
cd go-app
podman build -t my-go-app .
podman run -d -p 8080:8080 my-go-app
```

## Bonnes pratiques

1. Images de base minimales (alpine)
2. Multi-stage builds
3. Layer caching optimal
4. Utilisateur non-root
5. Fichier .dockerignore

## Suite

[TP3 - Podman Compose](../TP3-compose/)
