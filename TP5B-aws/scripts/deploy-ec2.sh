#!/bin/bash
# Script de déploiement EC2 pour le workshop Podman
# Usage: ./deploy-ec2.sh [--dry-run]

set -e

# Configuration (modifiable via variables d'environnement)
AWS_REGION=${AWS_REGION:-us-west-2}
KEY_NAME=${KEY_NAME:-podman-workshop-key}
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.micro}
SECURITY_GROUP=${SECURITY_GROUP:-podman-sg}

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_DATA_FILE="$SCRIPT_DIR/user-data.sh"

echo -e "${GREEN}=== Déploiement Podman sur EC2 ===${NC}"
echo "Region: $AWS_REGION"
echo "Type d'instance: $INSTANCE_TYPE"
echo "Clé SSH: $KEY_NAME"
echo "Security Group: $SECURITY_GROUP"
echo ""

# Vérifier les prérequis
if ! command -v aws &> /dev/null; then
    echo -e "${RED}[ERREUR] AWS CLI non installé${NC}"
    echo "Installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}[ERREUR] AWS CLI non configuré ou credentials invalides${NC}"
    echo "Configurez avec: aws configure"
    exit 1
fi

if [ ! -f "$USER_DATA_FILE" ]; then
    echo -e "${RED}[ERREUR] Fichier user-data.sh non trouvé: $USER_DATA_FILE${NC}"
    exit 1
fi

# Mode dry-run
if [ "$1" == "--dry-run" ]; then
    echo -e "${YELLOW}[DRY-RUN] Simulation uniquement${NC}"
    DRY_RUN="--dry-run"
else
    DRY_RUN=""
fi

# Étape 1: Trouver l'AMI Amazon Linux 2023 la plus récente
echo -e "\n${GREEN}[1/5] Recherche de l'AMI Amazon Linux 2023...${NC}"
AMI_ID=$(aws ec2 describe-images \
    --region "$AWS_REGION" \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
    echo -e "${RED}[ERREUR] Impossible de trouver une AMI Amazon Linux 2023${NC}"
    exit 1
fi
echo "AMI trouvée: $AMI_ID"

# Étape 2: Vérifier que le security group existe
echo -e "\n${GREEN}[2/5] Vérification du Security Group...${NC}"
if ! aws ec2 describe-security-groups --region "$AWS_REGION" --group-names "$SECURITY_GROUP" &> /dev/null; then
    echo -e "${YELLOW}[INFO] Security Group '$SECURITY_GROUP' non trouvé, création...${NC}"

    # Créer le security group
    SG_ID=$(aws ec2 create-security-group \
        --region "$AWS_REGION" \
        --group-name "$SECURITY_GROUP" \
        --description "Security group for Podman workshop" \
        --query 'GroupId' \
        --output text)

    # Ajouter les règles
    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" \
        --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" \
        --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" \
        --protocol tcp --port 443 --cidr 0.0.0.0/0

    echo "Security Group créé: $SG_ID"
else
    echo "Security Group '$SECURITY_GROUP' existe"
fi

# Étape 3: Vérifier que la clé SSH existe
echo -e "\n${GREEN}[3/5] Vérification de la clé SSH...${NC}"
if ! aws ec2 describe-key-pairs --region "$AWS_REGION" --key-names "$KEY_NAME" &> /dev/null; then
    echo -e "${RED}[ERREUR] Clé SSH '$KEY_NAME' non trouvée${NC}"
    echo "Créez-la avec: aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ~/.ssh/$KEY_NAME.pem"
    exit 1
fi
echo "Clé SSH '$KEY_NAME' trouvée"

# Étape 4: Lancer l'instance
echo -e "\n${GREEN}[4/5] Lancement de l'instance EC2...${NC}"
if [ -n "$DRY_RUN" ]; then
    echo "[DRY-RUN] Instance non lancée"
    exit 0
fi

INSTANCE_ID=$(aws ec2 run-instances \
    --region "$AWS_REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-groups "$SECURITY_GROUP" \
    --user-data file://"$USER_DATA_FILE" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=podman-workshop},{Key=Project,Value=podman-workshop}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance lancée: $INSTANCE_ID"

# Étape 5: Attendre que l'instance soit prête
echo -e "\n${GREEN}[5/5] Attente du démarrage de l'instance...${NC}"
echo "Cela peut prendre 1-2 minutes..."
aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"

# Obtenir l'IP publique
PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "\n${GREEN}=== Déploiement terminé ===${NC}"
echo ""
echo "Instance ID: $INSTANCE_ID"
echo "IP publique: $PUBLIC_IP"
echo ""
echo -e "${YELLOW}Note: Attendez 2-3 minutes pour que cloud-init termine l'installation de Podman${NC}"
echo ""
echo "Connexion SSH:"
echo "  ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo ""
echo "Vérifier les logs cloud-init:"
echo "  ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP 'sudo cat /var/log/user-data.log'"
echo ""
echo "Tester Podman:"
echo "  ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP './test-podman.sh'"
