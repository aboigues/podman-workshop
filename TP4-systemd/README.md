# TP4 - Automatisation avec Systemd

## Objectifs
- Integrer Podman avec systemd
- Automatiser le demarrage des conteneurs
- Gerer les services Podman

## Contenu

- `services/` - Exemples de fichiers unit systemd
- `scripts/` - Scripts d'automatisation

## Quick Start

```bash
# Generer un service
podman generate systemd --new --files --name my-container

# Installer
cp container-my-container.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now container-my-container.service
```

## Suite

[TP5A - Securite](../TP5A-securite/)
