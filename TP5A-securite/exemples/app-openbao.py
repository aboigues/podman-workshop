#!/usr/bin/env python3
"""
Application de démonstration utilisant OpenBao pour la gestion des secrets
Compatible avec HashiCorp Vault (même API)
"""

import os
import sys
import time
import logging
from typing import Dict, Any, Optional

try:
    import hvac
except ImportError:
    print("❌ Le module 'hvac' n'est pas installé.")
    print("Installation: pip install hvac")
    sys.exit(1)

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class OpenBaoClient:
    """Client pour interagir avec OpenBao (compatible Vault)"""

    def __init__(self, addr: str = None, token: str = None):
        """
        Initialise le client OpenBao

        Args:
            addr: URL d'OpenBao (défaut: BAO_ADDR env var)
            token: Token d'authentification (défaut: BAO_TOKEN env var)
        """
        self.addr = addr or os.getenv('BAO_ADDR', 'http://localhost:8200')
        self.token = token or os.getenv('BAO_TOKEN')

        if not self.token:
            raise ValueError(
                "Token OpenBao requis. Définir BAO_TOKEN ou passer token en paramètre"
            )

        # Créer le client hvac (compatible OpenBao)
        self.client = hvac.Client(url=self.addr, token=self.token)

        # Vérifier l'authentification
        if not self.client.is_authenticated():
            raise Exception("Échec de l'authentification avec OpenBao")

        logger.info(f"✅ Connecté à OpenBao: {self.addr}")

    def read_secret(self, path: str, mount_point: str = 'kv') -> Dict[str, Any]:
        """
        Lit un secret depuis OpenBao

        Args:
            path: Chemin du secret (ex: 'myapp/database')
            mount_point: Point de montage du moteur KV (défaut: 'kv')

        Returns:
            Dictionnaire contenant les données du secret

        Raises:
            Exception: Si le secret n'existe pas ou erreur de lecture
        """
        try:
            # KV v2 API
            response = self.client.secrets.kv.v2.read_secret_version(
                path=path,
                mount_point=mount_point
            )

            if not response or 'data' not in response:
                raise Exception(f"Secret '{path}' introuvable ou invalide")

            data = response['data']['data']
            logger.info(f"✅ Secret '{path}' lu avec succès")
            return data

        except Exception as e:
            logger.error(f"❌ Erreur lecture secret '{path}': {e}")
            raise

    def list_secrets(self, path: str = '', mount_point: str = 'kv') -> list:
        """
        Liste les secrets disponibles

        Args:
            path: Chemin de base (ex: 'myapp')
            mount_point: Point de montage du moteur KV

        Returns:
            Liste des secrets disponibles
        """
        try:
            response = self.client.secrets.kv.v2.list_secrets(
                path=path,
                mount_point=mount_point
            )

            if response and 'data' in response:
                return response['data'].get('keys', [])
            return []

        except Exception as e:
            logger.warning(f"Impossible de lister les secrets: {e}")
            return []

    def watch_secret(self, path: str, interval: int = 60, mount_point: str = 'kv'):
        """
        Surveille un secret et détecte les changements (versioning)

        Args:
            path: Chemin du secret
            interval: Intervalle de vérification en secondes
            mount_point: Point de montage du moteur KV
        """
        logger.info(f"👀 Surveillance du secret '{path}' (intervalle: {interval}s)")

        last_version = None

        while True:
            try:
                response = self.client.secrets.kv.v2.read_secret_version(
                    path=path,
                    mount_point=mount_point
                )

                current_version = response['data']['metadata']['version']

                if last_version is None:
                    logger.info(f"Version initiale: {current_version}")
                elif current_version != last_version:
                    logger.warning(
                        f"⚠️  Secret modifié! "
                        f"Version {last_version} → {current_version}"
                    )
                    logger.info("🔄 Rechargement de la configuration recommandé")

                last_version = current_version

            except Exception as e:
                logger.error(f"Erreur surveillance: {e}")

            time.sleep(interval)


def main():
    """Fonction principale de démonstration"""

    print("=== Démonstration OpenBao ===\n")

    try:
        # Initialiser le client OpenBao
        bao = OpenBaoClient()

        # Lister les secrets disponibles
        print("📋 Secrets disponibles dans myapp/:")
        secrets_list = bao.list_secrets('myapp')

        if not secrets_list:
            print("⚠️  Aucun secret trouvé!")
            print("Exécutez le script d'initialisation:")
            print("  podman-compose run openbao-init")
            return 1

        for secret_name in secrets_list:
            print(f"  - {secret_name}")

        print()

        # Récupérer les secrets de base de données
        print("🔐 Récupération des credentials de base de données...")
        db_secrets = bao.read_secret('myapp/database')

        db_config = {
            'host': db_secrets.get('host'),
            'port': db_secrets.get('port'),
            'database': db_secrets.get('database'),
            'username': db_secrets.get('username'),
            'password': db_secrets.get('password', '***')  # Masqué pour l'affichage
        }

        print("✅ Configuration DB récupérée:")
        print(f"   Host: {db_config['host']}")
        print(f"   Port: {db_config['port']}")
        print(f"   Database: {db_config['database']}")
        print(f"   Username: {db_config['username']}")
        print(f"   Password: {'*' * len(db_config['password'])}")

        # Récupérer la clé API
        print("\n🔑 Récupération de la clé API...")
        api_secrets = bao.read_secret('myapp/api')

        api_key = api_secrets.get('key')
        api_endpoint = api_secrets.get('endpoint')

        print("✅ Configuration API récupérée:")
        print(f"   Endpoint: {api_endpoint}")
        print(f"   Key: {api_key[:10]}... (longueur: {len(api_key)})")

        # Récupérer le secret JWT
        print("\n🎫 Récupération du secret JWT...")
        jwt_secrets = bao.read_secret('myapp/jwt')

        jwt_secret = jwt_secrets.get('secret')
        jwt_algo = jwt_secrets.get('algorithm')

        print("✅ Configuration JWT récupérée:")
        print(f"   Algorithm: {jwt_algo}")
        print(f"   Secret: {jwt_secret[:10]}... (longueur: {len(jwt_secret)})")

        print("\n" + "="*50)
        print("✅ Tous les secrets chargés avec succès!")
        print("="*50)

        # Exemple: Connexion simulée à la DB
        print(f"\n💾 Simulation connexion DB: postgresql://{db_config['username']}@{db_config['host']}:{db_config['port']}/{db_config['database']}")

        # En production, vous utiliseriez les secrets pour:
        # - Connexion à la base de données
        # - Appels API authentifiés
        # - Génération de tokens JWT
        # - etc.

        print("\n🔄 Mode watch activé (Ctrl+C pour quitter)...")
        print("Modifiez un secret dans OpenBao pour voir la détection de changement:")
        print("  bao kv put kv/myapp/database password='new_password_123'")

        # Surveiller les changements (boucle infinie)
        bao.watch_secret('myapp/database', interval=10)

    except KeyboardInterrupt:
        print("\n\n👋 Arrêt demandé par l'utilisateur")
        return 0
    except Exception as e:
        logger.error(f"❌ Erreur: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
