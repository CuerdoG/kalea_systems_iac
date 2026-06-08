#!/bin/bash
# push_iac.sh — Sube los archivos IaC de Kalea Systems a GitHub

REPO_URL="https://github.com/CuerdoG/kalea_systems_iac.git"
ORIGEN="/root/infraestructura"
DESTINO="/tmp/kalea_systems_iac"

# Limpiar y preparar directorio temporal
rm -rf "$DESTINO"
mkdir -p "$DESTINO/ansible"
mkdir -p "$DESTINO/terraform"

# Copiar archivos de ansible
cp "$ORIGEN/ansible/ansible.cfg"       "$DESTINO/ansible/"
cp "$ORIGEN/ansible/inventario.ini"    "$DESTINO/ansible/"
cp "$ORIGEN/ansible/playbook.yml"      "$DESTINO/ansible/"
cp "$ORIGEN/ansible/zabbix_agents.yml" "$DESTINO/ansible/"

# Copiar archivos de terraform (sin tfstate)
cp "$ORIGEN/terraform/main.tf"      "$DESTINO/terraform/"
cp "$ORIGEN/terraform/variables.tf" "$DESTINO/terraform/"
cp -r "$ORIGEN/terraform/modules"   "$DESTINO/terraform/"

# Copiar script de despliegue
cp "$ORIGEN/desplegar.py" "$DESTINO/"

# Crear .gitignore
cat > "$DESTINO/.gitignore" << 'EOF'
# Terraform - estado e información sensible
*.tfstate
*.tfstate.backup
*.tfstate.*.backup
.terraform/
.terraform.lock.hcl

# Variables con credenciales
*.tfvars
*.tfvars.json

# Python
__pycache__/
*.pyc

# Ansible - archivos temporales
*.retry
EOF

# Inicializar repo y subir
cd "$DESTINO"
git init
git remote add origin "$REPO_URL"
git add .
git commit -m "Subida inicial de IaC - Kalea Systems"
git branch -M main
git push -u origin main

echo "Subida completada a $REPO_URL"
