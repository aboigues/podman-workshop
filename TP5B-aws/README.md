# TP5B - Déploiement Podman sur AWS

## Objectifs
- Déployer Podman sur des instances EC2
- Automatiser l'infrastructure avec Terraform
- Gérer des conteneurs sur le cloud AWS
- Comprendre les coûts et l'optimisation
- Sécuriser les déploiements cloud
- Implémenter les bonnes pratiques AWS

## Prérequis

### Compte et outils AWS
- Compte AWS actif (Free Tier recommandé pour débuter)
- AWS CLI v2 installé et configuré
- Terraform >= 1.0 installé
- Paire de clés SSH pour EC2

### Permissions IAM nécessaires
- `ec2:*` (Gestion des instances)
- `iam:PassRole` (Création de rôles)
- `vpc:*` (Gestion réseau)
- Ou politique `PowerUserAccess` pour simplifier

### Connaissances
- Bases de Podman (TP1-TP4 recommandés)
- Concepts AWS (EC2, VPC, Security Groups)
- Terraform (bases)

## Démarrage rapide

```bash
# 1. Configurer AWS CLI
aws configure

# 2. Déployer avec Terraform
cd terraform
terraform init
terraform plan
terraform apply

# 3. Se connecter à l'instance
ssh -i ~/.ssh/your-key.pem ec2-user@<PUBLIC_IP>

# 4. Tester Podman
podman run hello-world

# 5. IMPORTANT : Nettoyer les ressources
terraform destroy
```

---

## Configuration AWS CLI

### Installation AWS CLI v2

**Linux :**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Vérifier
aws --version
```

**macOS :**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Windows :**
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

### Configuration des credentials

```bash
# Configuration interactive
aws configure

# Saisir :
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name: us-west-2
# Default output format: json
```

**Fichiers créés :**
- `~/.aws/credentials` : Clés d'accès
- `~/.aws/config` : Configuration régionale

### Vérification

```bash
# Tester la connexion
aws sts get-caller-identity

# Lister les régions disponibles
aws ec2 describe-regions --output table

# Vérifier les permissions
aws iam get-user
```

---

## Déploiement manuel sur EC2

### Étape 1 : Créer une paire de clés SSH

```bash
# Créer la clé
aws ec2 create-key-pair \
  --key-name podman-workshop-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/podman-workshop-key.pem

# Sécuriser la clé
chmod 400 ~/.ssh/podman-workshop-key.pem

# Lister les clés
aws ec2 describe-key-pairs
```

### Étape 2 : Créer un Security Group

```bash
# Créer le security group
aws ec2 create-security-group \
  --group-name podman-sg \
  --description "Security group for Podman instances"

# Autoriser SSH (port 22)
aws ec2 authorize-security-group-ingress \
  --group-name podman-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Autoriser HTTP (port 80) - optionnel
aws ec2 authorize-security-group-ingress \
  --group-name podman-sg \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

### Étape 3 : Lancer l'instance (méthode automatique recommandée)

Le script `deploy-ec2.sh` automatise tout le processus :

```bash
cd scripts/

# Lancer le déploiement
./deploy-ec2.sh

# Ou avec des options personnalisées
AWS_REGION=eu-west-1 KEY_NAME=ma-cle ./deploy-ec2.sh

# Mode simulation (sans créer l'instance)
./deploy-ec2.sh --dry-run
```

Le script va :
1. Trouver la dernière AMI Amazon Linux 2023
2. Vérifier/créer le Security Group
3. Lancer l'instance avec le user-data
4. Afficher les commandes de connexion

### Étape 3 alternative : Lancer manuellement

Si vous préférez lancer l'instance manuellement :

```bash
# Se placer dans le répertoire scripts (contient user-data.sh)
cd scripts/

# Trouver l'AMI Amazon Linux 2023 la plus récente
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

# Lancer l'instance avec le user-data fourni
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name podman-workshop-key \
  --security-groups podman-sg \
  --user-data file://user-data.sh \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance lancée : $INSTANCE_ID"

# Attendre que l'instance soit prête
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Obtenir l'IP publique
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "IP publique : $PUBLIC_IP"
```

### Étape 4 : Comprendre le User Data

Le fichier `scripts/user-data.sh` est exécuté automatiquement par cloud-init au premier démarrage. Il :

- Met à jour le système avec `dnf`
- Installe Podman, podman-compose et git
- Active le socket Podman
- Crée un script de test `/home/ec2-user/test-podman.sh`
- Log l'installation dans `/var/log/user-data.log`

> **Note** : Attendez 2-3 minutes après le démarrage de l'instance pour que cloud-init termine.

Pour vérifier que cloud-init a terminé :

```bash
# Voir les logs cloud-init
ssh -i ~/.ssh/podman-workshop-key.pem ec2-user@$PUBLIC_IP 'sudo cat /var/log/user-data.log'

# Vérifier le statut
ssh -i ~/.ssh/podman-workshop-key.pem ec2-user@$PUBLIC_IP 'cloud-init status'
```

### Étape 5 : Se connecter et tester

```bash
# Connexion SSH
ssh -i ~/.ssh/podman-workshop-key.pem ec2-user@$PUBLIC_IP

# Une fois connecté :
podman --version
podman run hello-world

# Lancer nginx
podman run -d --name nginx -p 80:80 nginx:alpine

# Depuis votre machine locale :
curl http://$PUBLIC_IP
```

---

## Déploiement avec Terraform

### Structure du projet

```
terraform/
├── main.tf           # Configuration principale
├── variables.tf      # Variables
├── outputs.tf        # Sorties
├── terraform.tfvars  # Valeurs des variables (gitignored)
└── README.md         # Documentation
```

### Configuration Terraform complète

**`main.tf` :**

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC par défaut
data "aws_vpc" "default" {
  default = true
}

# AMI Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Security Group
resource "aws_security_group" "podman_sg" {
  name        = "podman-sg-${var.environment}"
  description = "Security group for Podman workshop"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Sortie internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "podman-sg-${var.environment}"
  }
}

# Instance EC2
resource "aws_instance" "podman" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.podman_sg.id]

  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "podman-workshop-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

**`variables.tf` :**

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # ⚠️ Restreindre en production
}
```

**`outputs.tf` :**

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.podman.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.podman.public_ip
}

output "public_dns" {
  description = "Public DNS name"
  value       = aws_instance.podman.public_dns
}

output "ssh_command" {
  description = "Command to SSH to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.podman.public_ip}"
}
```

**`terraform.tfvars` :**

```hcl
aws_region    = "us-west-2"
instance_type = "t3.micro"
key_name      = "podman-workshop-key"
environment   = "dev"
```

### Utilisation de Terraform

```bash
# 1. Initialiser Terraform
cd terraform
terraform init

# 2. Valider la configuration
terraform validate

# 3. Voir le plan
terraform plan

# 4. Appliquer
terraform apply

# Saisir 'yes' pour confirmer

# 5. Voir les outputs
terraform output

# 6. Se connecter
ssh -i ~/.ssh/podman-workshop-key.pem ec2-user@$(terraform output -raw public_ip)

# 7. IMPORTANT : Détruire les ressources
terraform destroy
```

---

## Gestion des coûts

### Estimation des coûts

**Free Tier (12 premiers mois) :**
- 750 heures/mois de t2.micro ou t3.micro
- 30 Go de stockage EBS gp2
- 15 Go de bande passante sortante

**Coûts après Free Tier (us-west-2) :**
- t3.micro : ~$0.0104/heure (~$7.5/mois)
- t3.small : ~$0.0208/heure (~$15/mois)
- t3.medium : ~$0.0416/heure (~$30/mois)
- Stockage EBS gp3 : $0.08/Go/mois
- Bande passante sortante : $0.09/Go

### Optimisation des coûts

```bash
# 1. Utiliser Spot Instances (jusqu'à 90% moins cher)
# Dans Terraform :
spot_price    = "0.01"
instance_market_options {
  market_type = "spot"
}

# 2. Arrêter les instances non utilisées
aws ec2 stop-instances --instance-ids $INSTANCE_ID

# 3. Programmer l'arrêt automatique
# Ajouter dans user-data.sh :
echo "sudo shutdown -h 23:00" | crontab -

# 4. Nettoyer régulièrement
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped"
```

### Monitoring des coûts

```bash
# Voir les coûts estimés
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Configurer des alertes de budget
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json
```

---

## Bonnes pratiques AWS

### Sécurité

✅ **Restreindre les Security Groups**
```hcl
# Mauvais
cidr_blocks = ["0.0.0.0/0"]

# Bon
cidr_blocks = ["YOUR_IP/32"]
```

✅ **Utiliser des rôles IAM**
```hcl
resource "aws_iam_role" "podman_role" {
  name = "podman-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
```

✅ **Chiffrer les volumes EBS**
```hcl
root_block_device {
  encrypted = true
}
```

✅ **Pas de credentials dans le code**
- Utiliser AWS Secrets Manager ou Parameter Store
- Variables d'environnement
- Rôles IAM

### Haute disponibilité

```hcl
# Multiple availability zones
resource "aws_instance" "podman" {
  count             = 2
  availability_zone = element(var.availability_zones, count.index)

  # ... reste de la config
}

# Auto Scaling Group
resource "aws_autoscaling_group" "podman_asg" {
  desired_capacity = 2
  max_size         = 4
  min_size         = 1

  # ... config
}
```

### Backup et récupération

```bash
# Créer un snapshot EBS
aws ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "Backup Podman instance"

# Créer une AMI depuis l'instance
aws ec2 create-image \
  --instance-id $INSTANCE_ID \
  --name "podman-backup-$(date +%Y%m%d)"
```

---

## Validation

Vous avez réussi si vous pouvez :

- Configurer AWS CLI avec vos credentials
- Créer et gérer une paire de clés SSH pour EC2
- Déployer une instance EC2 manuellement via AWS CLI
- Automatiser le déploiement avec Terraform
- Installer et configurer Podman sur EC2
- Gérer les Security Groups pour contrôler l'accès
- Comprendre et optimiser les coûts AWS
- Nettoyer proprement les ressources avec `terraform destroy`
- Appliquer les bonnes pratiques de sécurité AWS

---

## Résolution de problèmes

### Erreur : Unable to locate credentials

```bash
# Problème : AWS CLI pas configuré
# Solution : Configurer les credentials
aws configure

# Vérifier
aws sts get-caller-identity
```

---

### Instance ne démarre pas

```bash
# Vérifier les logs cloud-init
ssh ec2-user@$PUBLIC_IP
sudo cat /var/log/cloud-init-output.log

# Voir le status de l'instance
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID
```

---

### Impossible de se connecter en SSH

```bash
# 1. Vérifier le Security Group
aws ec2 describe-security-groups --group-names podman-sg

# 2. Vérifier la clé
ls -la ~/.ssh/podman-workshop-key.pem
chmod 400 ~/.ssh/podman-workshop-key.pem

# 3. Vérifier l'instance est running
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].State.Name'

# 4. Tester la connexion
ssh -v -i ~/.ssh/podman-workshop-key.pem ec2-user@$PUBLIC_IP
```

---

### Terraform apply échoue

```bash
# Vérifier les permissions IAM
aws iam get-user

# Vérifier la syntaxe
terraform validate

# Voir les détails de l'erreur
terraform apply -debug

# Réinitialiser l'état si nécessaire
terraform state list
terraform state rm <resource>
```

---

### Coûts inattendus

```bash
# Lister toutes les instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table

# Lister les volumes EBS orphelins
aws ec2 describe-volumes --filters "Name=status,Values=available" --output table

# Lister les snapshots
aws ec2 describe-snapshots --owner-ids self --output table

# Nettoyer
terraform destroy  # Pour les ressources Terraform
aws ec2 terminate-instances --instance-ids <id>  # Instances orphelines
aws ec2 delete-volume --volume-id <id>  # Volumes orphelins
```

---

### Terraform destroy échoue

```bash
# Forcer la suppression d'une ressource
terraform state rm aws_instance.podman

# Supprimer manuellement via CLI
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Nettoyer l'état Terraform
terraform refresh
```

---

## Checklist de nettoyage

Avant de terminer, vérifier :

- [ ] `terraform destroy` exécuté avec succès
- [ ] Aucune instance EC2 en cours d'exécution
- [ ] Aucun volume EBS orphelin
- [ ] Aucun snapshot inutile
- [ ] Aucune Elastic IP non attachée
- [ ] Security Groups supprimés ou par défaut uniquement

```bash
# Script de vérification
#!/bin/bash

echo "=== Vérification des ressources AWS ==="

echo "Instances EC2:"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

echo "Volumes EBS:"
aws ec2 describe-volumes --query 'Volumes[*].[VolumeId,State]' --output table

echo "Snapshots:"
aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[*].[SnapshotId,StartTime]' --output table

echo "Security Groups (hors défaut):"
aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]' --output table
```

---

## Ressources additionnelles

### Documentation officielle

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Podman on RHEL](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/building_running_and_managing_containers/index)

### Tutoriels et guides

- AWS Free Tier : https://aws.amazon.com/free/
- Terraform Getting Started : https://learn.hashicorp.com/terraform
- AWS Well-Architected Framework : https://aws.amazon.com/architecture/well-architected/

---

## Conclusion

Ce TP vous a permis de :

✅ Déployer Podman sur AWS EC2
✅ Automatiser avec Terraform
✅ Comprendre les coûts AWS
✅ Appliquer les bonnes pratiques de sécurité
✅ Nettoyer proprement les ressources

**⚠️ RAPPEL IMPORTANT :** N'oubliez jamais de détruire vos ressources AWS après utilisation pour éviter les coûts imprévus !

```bash
terraform destroy  # Toujours vérifier que c'est bien fait
```
