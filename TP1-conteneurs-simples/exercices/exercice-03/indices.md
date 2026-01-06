# 💡 Indices pour l'Exercice 3

## Étape 1 : Créer le conteneur
```bash
podman run -d --name lifecycle-test -p 8888:80 nginx:latest
```

## Étape 2 : Arrêter le conteneur
```bash
podman stop lifecycle-test
```

## Étape 3 : Lister tous les conteneurs
```bash
podman ps -a
```
L'option `-a` affiche TOUS les conteneurs, même ceux arrêtés.

## Étape 4 : Redémarrer le conteneur
```bash
podman start lifecycle-test
```
Note : `start` pour un conteneur arrêté, `restart` pour un conteneur en cours.

## Étape 5 : Supprimer le conteneur
```bash
podman rm -f lifecycle-test
```
L'option `-f` force la suppression (arrête puis supprime).

## 🔄 États d'un conteneur
```
Created → Running → Stopped → Removed
          ↑________↓
        start/restart/stop
```
