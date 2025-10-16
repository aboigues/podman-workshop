#!/bin/bash

set -e

AWS_REGION=${AWS_REGION:-us-west-2}
KEY_NAME=${KEY_NAME:-podman-workshop-key}
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.medium}

echo "Deploiement Podman sur EC2"
echo "Region: $AWS_REGION"
echo "Type: $INSTANCE_TYPE"

if ! command -v aws &> /dev/null; then
    echo "[ERREUR] AWS CLI non installe"
    exit 1
fi

cat > /tmp/user-data.sh << 'USERDATA'
#!/bin/bash
yum update -y
yum install -y podman git
echo "Podman installe" > /var/log/podman-install.log
USERDATA

echo "[OK] Script pret"
echo "Utilisez AWS Console ou CLI pour lancer l'instance"
