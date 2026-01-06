# Exercice 3 : Gérer le cycle de vie des conteneurs

## 🎯 Objectifs
- Arrêter un conteneur en cours d'exécution
- Redémarrer un conteneur arrêté
- Supprimer un conteneur
- Comprendre les différents états d'un conteneur

## 📚 Contexte
Un conteneur a plusieurs états dans son cycle de vie :
- **Created** : Créé mais pas encore démarré
- **Running** : En cours d'exécution
- **Paused** : Mis en pause
- **Stopped** : Arrêté
- **Removed** : Supprimé

Dans cet exercice, vous allez manipuler ces états.

## 📝 Instructions

### Étape 1 : Créer un conteneur nginx
Lancez un conteneur nginx nommé **lifecycle-test** sur le port 8888.

### Étape 2 : Arrêter le conteneur
Arrêtez le conteneur **lifecycle-test** avec `podman stop`.

### Étape 3 : Vérifier l'état
Listez TOUS les conteneurs (y compris ceux arrêtés) pour voir l'état.

### Étape 4 : Redémarrer le conteneur
Redémarrez le conteneur **lifecycle-test** avec `podman start`.

### Étape 5 : Supprimer le conteneur
Arrêtez et supprimez le conteneur en une seule commande avec `podman rm -f`.

## 💡 Concepts clés

```bash
podman stop CONTENEUR      # Arrête un conteneur (SIGTERM puis SIGKILL)
podman start CONTENEUR     # Démarre un conteneur arrêté
podman restart CONTENEUR   # Redémarre un conteneur
podman rm CONTENEUR        # Supprime un conteneur (doit être arrêté)
podman rm -f CONTENEUR     # Force la suppression (arrête puis supprime)
podman ps -a               # Liste TOUS les conteneurs
```

## ✅ Critères de validation
- ✓ Comprendre comment arrêter un conteneur
- ✓ Comprendre comment redémarrer un conteneur arrêté
- ✓ Comprendre comment supprimer un conteneur
- ✓ Savoir lister tous les conteneurs (même arrêtés)

## 🚀 À vous de jouer !
1. Ouvrez `commandes.sh`
2. Complétez les commandes
3. Exécutez : `./commandes.sh`
4. Validez : `./validation.sh`
