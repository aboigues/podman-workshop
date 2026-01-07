#!/usr/bin/env python3
"""
Application de démonstration utilisant Podman Secrets
Montre comment lire des secrets de manière sécurisée
"""

import sys
from pathlib import Path
from typing import Optional
import logging

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SecretManager:
    """Gestionnaire de secrets Podman"""

    SECRETS_DIR = Path('/run/secrets')

    @classmethod
    def read_secret(cls, secret_name: str) -> str:
        """
        Lit un secret Podman de manière sécurisée

        Args:
            secret_name: Nom du secret à lire

        Returns:
            Le contenu du secret (sans espaces de début/fin)

        Raises:
            FileNotFoundError: Si le secret n'existe pas
            PermissionError: Si les permissions du secret sont incorrectes
            ValueError: Si le secret est vide
        """
        secret_path = cls.SECRETS_DIR / secret_name

        # Vérifier l'existence
        if not secret_path.exists():
            raise FileNotFoundError(
                f"Secret '{secret_name}' introuvable à {secret_path}"
            )

        # Vérifier les permissions (doit être 400 ou 600)
        stat_info = secret_path.stat()
        if stat_info.st_mode & 0o077:
            raise PermissionError(
                f"Secret '{secret_name}' a des permissions non sécurisées: "
                f"{oct(stat_info.st_mode)[-3:]}"
            )

        # Lire le contenu
        content = secret_path.read_text().strip()

        if not content:
            raise ValueError(f"Secret '{secret_name}' est vide")

        logger.info(f"Secret '{secret_name}' lu avec succès")
        return content

    @classmethod
    def read_secret_or_env(cls, secret_name: str, env_var: str) -> Optional[str]:
        """
        Tente de lire un secret Podman, sinon fallback sur variable d'env

        Args:
            secret_name: Nom du secret Podman
            env_var: Nom de la variable d'environnement fallback

        Returns:
            Le contenu du secret ou de la variable d'env, ou None
        """
        try:
            return cls.read_secret(secret_name)
        except FileNotFoundError:
            import os
            value = os.getenv(env_var)
            if value:
                logger.warning(
                    f"Secret '{secret_name}' introuvable, "
                    f"utilisation de la variable d'env '{env_var}' (non recommandé)"
                )
            return value

    @classmethod
    def list_available_secrets(cls) -> list[str]:
        """Liste tous les secrets disponibles"""
        if not cls.SECRETS_DIR.exists():
            return []

        return [
            f.name for f in cls.SECRETS_DIR.iterdir()
            if f.is_file()
        ]


def main():
    """Fonction principale de démonstration"""

    print("=== Démonstration Podman Secrets ===\n")

    # 1. Lister les secrets disponibles
    available_secrets = SecretManager.list_available_secrets()
    print(f"📋 Secrets disponibles: {', '.join(available_secrets) if available_secrets else 'Aucun'}\n")

    if not available_secrets:
        print("⚠️  Aucun secret trouvé!")
        print("Pour tester cette application, créez des secrets:")
        print("  echo 'my_password' | podman secret create db_password -")
        print("  echo 'my_api_key' | podman secret create api_key -")
        print("\nPuis lancez:")
        print("  podman run --secret db_password --secret api_key myapp")
        return 1

    # 2. Lire les secrets
    secrets_to_read = ['db_password', 'api_key']

    for secret_name in secrets_to_read:
        try:
            value = SecretManager.read_secret(secret_name)
            # Ne JAMAIS logger la valeur du secret!
            print(f"✅ Secret '{secret_name}' chargé (longueur: {len(value)} caractères)")

            # Simulation d'utilisation du secret
            # Dans une vraie application, vous l'utiliseriez pour vous connecter à une DB, API, etc.
            if secret_name == 'db_password':
                print(f"   → Utilisation pour connexion base de données")
            elif secret_name == 'api_key':
                print(f"   → Utilisation pour authentification API")

        except FileNotFoundError as e:
            print(f"❌ {e}")
        except PermissionError as e:
            print(f"⚠️  {e}")
        except ValueError as e:
            print(f"⚠️  {e}")

    print("\n✅ Application démarrée avec succès!")
    print("🔒 Les secrets sont stockés de manière sécurisée en mémoire (tmpfs)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
