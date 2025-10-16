# TP5B - Deploiement sur AWS

## Objectifs
- Deployer Podman sur EC2
- Utiliser ECS avec Podman
- Automatiser avec Terraform/CloudFormation

## Prerequis AWS

- Compte AWS actif
- AWS CLI configure
- Permissions EC2/ECS/IAM

## Contenu

- `terraform/` - Infrastructure as Code
- `scripts/` - Scripts de deploiement

## Quick Start

```bash
# Avec script
./scripts/deploy-ec2.sh

# Avec Terraform
cd terraform
terraform init
terraform apply
```

## Important

N'oubliez pas de detruire les ressources :
```bash
terraform destroy
```
