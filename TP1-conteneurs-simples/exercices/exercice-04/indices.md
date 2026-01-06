# 💡 Indices pour l'Exercice 4

## Étape 1 : Mode interactif
```bash
podman run -it alpine /bin/sh
```
- `-i` : Interactif (garde STDIN ouvert)
- `-t` : TTY (alloue un pseudo-terminal)
- `/bin/sh` : Le shell à lancer

## Étape 3 : Exec
```bash
podman exec exec-test nginx -v
```

### Différence run vs exec
```bash
# RUN : Crée un NOUVEAU conteneur
podman run nginx nginx -v

# EXEC : Exécute dans un conteneur EXISTANT
podman exec mon-conteneur nginx -v
```
