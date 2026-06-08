# -*- coding: utf-8 -*-

import os
import time
import subprocess
from getpass import getpass

proxmox_pass = getpass("Contrasena Proxmox: ")
admin_pass = getpass("Contrasena Root: ")

print("")
print("Que quieres desplegar?")
print("1. Toda la infraestructura")
print("2. Una maquina en especifico")

while True:
    opcion = input("Elige una opcion (1-2): ")

    if opcion == "1":
        targets = (
            "-target=proxmox_virtual_environment_container.Wordpress "
            "-target=proxmox_virtual_environment_container.MariaDB "
            "-target=proxmox_virtual_environment_vm.bastion"
        )
        ips = [("10.0.30.203", "root"), ("10.0.40.203", "root")]
        ct_ids = ["202", "203"]
        limite = "all"
        break

    elif opcion == "2":
        print("Maquinas disponibles:")
        print("  1. WordPress")
        print("  2. MariaDB")
        print("  3. Bastion")

        while True:
            maquina = input("Elige una opcion (1-3): ")

            if maquina == "1":
                targets = "-target=proxmox_virtual_environment_container.Wordpress"
                ips = [("10.0.30.203", "root")]
                ct_ids = ["202"]
                limite = "vm_wordpress"
                break
            elif maquina == "2":
                targets = "-target=proxmox_virtual_environment_container.MariaDB"
                ips = [("10.0.40.203", "root")]
                ct_ids = ["203"]
                limite = "vm_mariadb"
                break
            elif maquina == "3":
                targets = "-target=proxmox_virtual_environment_vm.bastion"
                ips = []
                ct_ids = []
                limite = None
                break
            else:
                print("Opcion no valida")
        break

    else:
        print("Opcion no valida")

env = os.environ.copy()
env["TF_VAR_pm_password"] = proxmox_pass
env["TF_VAR_ad_password"] = admin_pass

os.chdir("/root/infraestructura/terraform")
subprocess.run("terraform init -input=false", shell=True, env=env, capture_output=True)
resultado = subprocess.run(f"terraform apply {targets} -parallelism=1 -auto-approve", shell=True, env=env)
if resultado.returncode != 0:
    print("Error en Terraform")
    exit()

for ip, _ in ips:
    subprocess.run(f"ssh-keygen -f ~/.ssh/known_hosts -R {ip}", shell=True, capture_output=True)

# Preparar contenedores: inyectar clave SSH, habilitar root login y poner contrasena
if ct_ids:
    print("")
    print("Preparando contenedores para SSH...")
    pubkey = open(os.path.expanduser("~/.ssh/id_rsa.pub")).read().strip()
    for ct_id in ct_ids:
        print(f"  Configurando CT {ct_id}...", end="", flush=True)
        time.sleep(5)
        cmds = [
            f"pct exec {ct_id} -- bash -c 'mkdir -p /root/.ssh && echo \"{pubkey}\" >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'",
            f"pct exec {ct_id} -- bash -c 'sed -i \"s/#PermitRootLogin.*/PermitRootLogin yes/\" /etc/ssh/sshd_config && sed -i \"s/#PasswordAuthentication.*/PasswordAuthentication yes/\" /etc/ssh/sshd_config && systemctl restart sshd'",
            f"pct exec {ct_id} -- bash -c 'echo \"root:{admin_pass}\" | chpasswd'",
        ]
        for cmd in cmds:
            subprocess.run(f"ssh -o StrictHostKeyChecking=no root@192.168.1.220 \"{cmd}\"", shell=True, capture_output=True)
        print(" listo")

if ips:
    print("")
    print("Esperando conexion a las maquinas")
    for ip, user in ips:
        print(f"  Esperando {ip}...", end="", flush=True)
        while True:
            r = subprocess.run(
                f"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
                f"-o ConnectTimeout=5 -o BatchMode=yes {user}@{ip} true",
                shell=True, capture_output=True
            )
            if r.returncode == 0:
                print(" listo")
                break
            print(".", end="", flush=True)
            time.sleep(5)

if limite:
    os.chdir("/root/infraestructura/ansible")
    subprocess.run(f"ansible-playbook -i inventario.ini playbook.yml --limit {limite}", shell=True)
