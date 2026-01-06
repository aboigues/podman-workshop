# 💡 Indices pour l'Exercice 2

## 🎯 Étape 1 : Créer un conteneur qui génère des logs

### Indice Niveau 1
Vous devez lancer un conteneur busybox en mode détaché avec un nom personnalisé.

### Indice Niveau 2
```bash
podman run [MODE_DÉTACHÉ] --name [NOM] busybox [COMMANDE]
```

### Indice Niveau 3
```bash
podman run -d --name log-generator busybox sh -c "while true; do echo \"[$(date)] Message de log - Compteur: \$RANDOM\"; sleep 1; done"
```

---

## 🎯 Étape 2 : Afficher tous les logs

### Indice Niveau 1
La commande pour voir les logs est `podman logs` suivie du nom du conteneur.

### Indice Niveau 2
```bash
podman logs [NOM_CONTENEUR]
```

### Indice Niveau 3
```bash
podman logs log-generator
```

---

## 🎯 Étape 3 : Afficher les 5 dernières lignes

### Indice Niveau 1
Utilisez l'option `--tail` pour limiter le nombre de lignes affichées.

### Indice Niveau 2
```bash
podman logs --tail [NOMBRE] [NOM_CONTENEUR]
```

### Indice Niveau 3
```bash
podman logs --tail 5 log-generator
```

---

## 🎯 Étape 4 : Suivre les logs en temps réel

### Indice Niveau 1
L'option `-f` ou `--follow` permet de suivre les logs en temps réel.

### Indice Niveau 2
```bash
podman logs [OPTION_FOLLOW] [NOM_CONTENEUR]
```

### Indice Niveau 3
```bash
podman logs -f log-generator
```

Note : Utilisez Ctrl+C pour arrêter le suivi en temps réel.

---

## 📚 Options utiles de podman logs

```bash
podman logs conteneur              # Tous les logs
podman logs --tail 10 conteneur    # 10 dernières lignes
podman logs -f conteneur           # Temps réel (follow)
podman logs --since 5m conteneur   # Logs des 5 dernières minutes
podman logs --since 2h conteneur   # Logs des 2 dernières heures
podman logs -t conteneur           # Afficher les timestamps
podman logs --until 10m conteneur  # Logs jusqu'à il y a 10 minutes
```

---

## 🆘 Problèmes courants

### Le conteneur ne génère pas de logs
```bash
# Vérifier que le conteneur tourne
podman ps | grep log-generator

# Vérifier les logs (même vides)
podman logs log-generator

# Si rien n'apparaît, le conteneur s'est peut-être arrêté
podman ps -a | grep log-generator
```

### "Error: no logs found"
Le conteneur n'a probablement pas démarré correctement :
```bash
# Voir l'état du conteneur
podman ps -a

# Voir pourquoi il s'est arrêté
podman logs log-generator
podman inspect log-generator
```
