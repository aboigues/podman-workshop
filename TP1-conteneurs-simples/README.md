# TP1 - Creation d'un conteneur simple

## Objectifs
- Lancer un conteneur avec Podman
- Comprendre les etats d'un conteneur
- Gerer l'arret et la suppression
- Explorer les logs

## Prerequis
- Podman installe
- Acces terminal
- Connexion internet

## Demarrage rapide

```bash
# Test rapide
./exercices/quick-test.sh

# Demo complete
./exercices/demo-complete.sh

# Solutions
cat solutions/exercice1-solution.sh
```

## Exercices

### Exercice 1 : Premier conteneur
```bash
podman run -d --name mon-nginx -p 8080:80 nginx:latest
podman ps
curl http://localhost:8080
```

### Exercice 2 : Logs
```bash
podman logs mon-nginx
podman logs -f mon-nginx
podman logs --tail 10 mon-nginx
```

### Exercice 3 : Cycle de vie
```bash
podman stop mon-nginx
podman ps -a
podman start mon-nginx
podman rm -f mon-nginx
```

### Exercice 4 : Mode interactif
```bash
podman run -it --name mon-ubuntu ubuntu:latest /bin/bash
# Dans le conteneur :
whoami
ls -la
exit
```

## Commandes essentielles

| Commande | Description |
|----------|-------------|
| `podman run` | Creer et demarrer |
| `podman ps` | Lister actifs |
| `podman ps -a` | Lister tous |
| `podman stop` | Arreter |
| `podman start` | Demarrer |
| `podman rm` | Supprimer |
| `podman logs` | Voir logs |
| `podman exec` | Executer commande |

## Validation

Vous avez reussi si vous pouvez :
- Lancer un conteneur en arriere-plan
- Consulter ses logs
- Arreter et redemarrer
- Executer des commandes
- Supprimer proprement

## Suite

Passez au [TP2](../TP2-dockerfile/)
