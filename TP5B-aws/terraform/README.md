# Terraform pour AWS

## Utilisation

```bash
# Initialiser
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply

# Detruire
terraform destroy
```

## Variables

Creer `terraform.tfvars`:
```hcl
aws_region = "us-west-2"
instance_type = "t3.medium"
```
