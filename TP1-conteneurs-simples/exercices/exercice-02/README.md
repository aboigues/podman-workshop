# Exercice 2 : Consulter les logs des conteneurs

## 🎯 Objectifs
- Afficher les logs d'un conteneur
- Suivre les logs en temps réel
- Limiter le nombre de lignes affichées
- Comprendre l'importance des logs pour le débogage

## 📚 Contexte
Les logs sont essentiels pour :
- Débugger des problèmes
- Surveiller l'activité d'un conteneur
- Comprendre ce qui se passe dans le conteneur

Dans cet exercice, vous allez créer un conteneur qui génère des logs, puis les consulter de différentes manières.

## 📝 Instructions

### Étape 1 : Créer un conteneur qui génère des logs
Lancez un conteneur **busybox** qui :
- Se nomme **log-generator**
- Exécute une boucle qui affiche l'heure toutes les secondes
- Tourne en arrière-plan

Commande à exécuter dans le conteneur :
```bash
sh -c "while true; do echo \"[$(date)] Message de log - Compteur: $RANDOM\"; sleep 1; done"
```

### Étape 2 : Afficher tous les logs
Affichez tous les logs du conteneur **log-generator**.

### Étape 3 : Afficher les 5 dernières lignes
Affichez seulement les **5 dernières lignes** de logs.

### Étape 4 : Suivre les logs en temps réel
Affichez les logs en **temps réel** (mode follow) pendant quelques secondes, puis interrompez avec Ctrl+C.

## 💡 Concepts clés

### La commande podman logs
```bash
podman logs CONTENEUR        # Affiche tous les logs
podman logs --tail N         # Affiche les N dernières lignes
podman logs -f               # Suit les logs en temps réel (follow)
podman logs --since 10m      # Logs des 10 dernières minutes
```

### Pourquoi les logs sont importants
- Débugger : Voir les erreurs et exceptions
- Monitoring : Surveiller l'activité
- Audit : Tracer les actions effectuées
- Performance : Identifier les lenteurs

## ✅ Critères de validation

Votre exercice sera validé si :
- ✓ Un conteneur nommé 'log-generator' existe et tourne
- ✓ Les logs contiennent bien des messages horodatés
- ✓ Vous savez afficher tous les logs
- ✓ Vous savez limiter le nombre de lignes avec --tail
- ✓ Vous comprenez le mode follow (-f)

## 🚀 À vous de jouer !

1. Ouvrez `commandes.sh`
2. Complétez les commandes
3. Exécutez : `./commandes.sh`
4. Validez : `./validation.sh`

## 📖 Commandes utiles

```bash
# Aide
podman logs --help
man podman-logs

# Options courantes
podman logs conteneur           # Tous les logs
podman logs --tail 10 conteneur # 10 dernières lignes
podman logs -f conteneur        # Temps réel (Ctrl+C pour arrêter)
podman logs --since 5m conteneur # 5 dernières minutes
```
