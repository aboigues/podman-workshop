# Terraform - Déploiement AWS TaskPlatform

Ce dossier contient la configuration Terraform pour déployer la stack TaskPlatform sur AWS.

## Prérequis

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configuré avec vos credentials
- Une paire de clés SSH dans AWS EC2

## Architecture déployée

```
AWS Cloud
├── VPC (default)
│   └── EC2 Instance (t3.medium)
│       ├── Amazon Linux 2023
│       ├── Podman + podman-compose
│       └── Stack TaskPlatform
│           ├── Frontend (React)
│           ├── Backend (Node.js)
│           ├── PostgreSQL
│           ├── Redis
│           ├── Nginx (port 8080)
│           ├── Prometheus (port 9090)
│           └── Grafana (port 3001)
└── Security Group
    ├── SSH (22)
    ├── App (8080)
    ├── Grafana (3001)
    └── Prometheus (9090)
```

## Utilisation rapide

```bash
# 1. Créer une paire de clés SSH (si nécessaire)
aws ec2 create-key-pair --key-name taskplatform-key --query 'KeyMaterial' --output text > ~/.ssh/taskplatform-key.pem
chmod 400 ~/.ssh/taskplatform-key.pem

# 2. Initialiser Terraform
terraform init

# 3. Vérifier le plan
terraform plan

# 4. Déployer
terraform apply

# 5. Récupérer les URLs
terraform output
```

## Variables

| Variable | Description | Défaut |
|----------|-------------|--------|
| `aws_region` | Région AWS | `eu-west-3` |
| `instance_type` | Type d'instance EC2 | `t3.medium` |
| `key_name` | Nom de la paire de clés SSH | `taskplatform-key` |
| `environment` | Nom de l'environnement | `production` |
| `allowed_ssh_cidr` | CIDR autorisé pour SSH | `["0.0.0.0/0"]` |
| `git_repo` | URL du repository Git | `https://github.com/aboigues/podman-workshop.git` |

### Personnaliser les variables

Créer un fichier `terraform.tfvars` :

```hcl
aws_region       = "eu-west-1"
instance_type    = "t3.large"
key_name         = "ma-cle-ssh"
environment      = "staging"
allowed_ssh_cidr = ["203.0.113.0/24"]
```

## Outputs

Après le déploiement, Terraform affiche :

```bash
# IP publique
terraform output public_ip

# URL de l'application
terraform output app_url

# URL Grafana
terraform output grafana_url

# Commande SSH
terraform output ssh_command
```

## Connexion à l'instance

```bash
# Se connecter en SSH
ssh -i ~/.ssh/taskplatform-key.pem ec2-user@$(terraform output -raw public_ip)

# Une fois connecté, vérifier l'état
tp status

# Vérifier les health checks
tp health

# Voir les logs
tp logs
```

## Accès aux services

| Service | Port | URL |
|---------|------|-----|
| Application | 8080 | `http://<IP>:8080` |
| API | 8080 | `http://<IP>:8080/api` |
| Grafana | 3001 | `http://<IP>:3001` |
| Prometheus | 9090 | `http://<IP>:9090` |

Le mot de passe Grafana est généré automatiquement et disponible dans :
```bash
cat ~/grafana-credentials.txt
```

## Destruction

```bash
# Détruire toutes les ressources
terraform destroy
```

## Dépannage

### L'instance ne démarre pas les conteneurs

Vérifier les logs de user-data :
```bash
sudo cat /var/log/user-data.log
```

### Les services ne répondent pas

1. Vérifier l'état des conteneurs :
   ```bash
   tp status
   ```

2. Vérifier les logs :
   ```bash
   tp logs backend
   tp logs postgres
   ```

3. Redémarrer la stack :
   ```bash
   tp restart
   ```

### Problèmes de permissions

S'assurer que le linger est activé :
```bash
loginctl show-user ec2-user | grep Linger
```

## Coûts estimés

- **t3.medium** : ~$0.0416/heure (~$30/mois)
- **Volume EBS 30GB gp3** : ~$2.40/mois
- **Transfert données** : Variable selon utilisation

Pour réduire les coûts en environnement de test :
```hcl
instance_type = "t3.micro"
```
