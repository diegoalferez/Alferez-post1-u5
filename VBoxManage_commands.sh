# VBoxManage_commands.sh - Parte 2 (VirtualBox) - Post-contenido Emuladores y Virtualizacion (U5)
# Comandos ejecutados en PowerShell (Windows) con VirtualBox 7.2.20. VM: Lab5-Alpine.
# Los discos (.vdi) y la exportacion (.ova) quedan en la carpeta "VirtualBox VMs" del usuario, FUERA del repositorio.
# Las lineas [DENTRO DE LA VM] se escriben en la consola de Alpine; las lineas [GUI] se hicieron en la interfaz grafica.

# ---------------------------------------------------------------
# 0. Preparacion
# ---------------------------------------------------------------
$env:Path += ";C:\Program Files\Oracle\VirtualBox"
VBoxManage --version

# ---------------------------------------------------------------
# PASO 1 - Creacion de la VM (opcion A de la guia: asistente grafico)
# ---------------------------------------------------------------
# [GUI] Nueva -> Nombre: Lab5-Alpine | ISO: alpine-standard-3.19.1-x86_64.iso
# [GUI] Tipo: Linux | Version: Other Linux (64-bit) | Instalacion desatendida: desactivada
# [GUI] Memoria: 1024 MB | CPUs: 1 | Disco: VDI nuevo de 10 GB, asignacion dinamica | Red: NAT

# ---------------------------------------------------------------
# PASO 2 - Instalacion de Alpine Linux
# ---------------------------------------------------------------
# [DENTRO DE LA VM] login: root (sin contrasena) y luego: setup-alpine
#   teclado us/us, hostname lab5-vm, eth0 con dhcp, DNS 8.8.8.8, zona America/Bogota,
#   proxy none, NTP chrony, mirror 1, usuario no, SSH openssh, disco sda, modo sys, borrar y
# [DENTRO DE LA VM] poweroff
# [GUI] Configuracion -> Almacenamiento -> quitar el ISO de la unidad optica
# [DENTRO DE LA VM] ip addr show eth0
# [DENTRO DE LA VM] ping -c 3 8.8.8.8

# ---------------------------------------------------------------
# PASO 3 - Modos de red (cada cambio con la VM apagada)
# ---------------------------------------------------------------
# [GUI] Configuracion -> Red -> Adaptador 1 -> Adaptador solo anfitrion (VirtualBox Host-Only Ethernet Adapter)
# [DENTRO DE LA VM] ip addr show eth0 ; ping -c 3 8.8.8.8      (falla: sin internet en Host-Only)
# [EN EL ANFITRION] ping 192.168.56.102                        (responde)
# [GUI] Configuracion -> Red -> Adaptador 1 -> Adaptador puente (Realtek PCIe GbE Family Controller)
# [DENTRO DE LA VM] ip addr show eth0 ; ping -c 3 8.8.8.8      (IP 192.168.40.9, responde)
# [EN EL ANFITRION] ping 192.168.40.9                          (responde)
# [GUI] Configuracion -> Red -> Adaptador 1 -> NAT (para los pasos siguientes)

# ---------------------------------------------------------------
# PASO 4 - Snapshots (VM encendida y en NAT)
# ---------------------------------------------------------------
VBoxManage snapshot "Lab5-Alpine" take "snap_base" --description "Alpine Linux 3.19 recien instalado, sin modificaciones"
# [DENTRO DE LA VM] apk update
# [DENTRO DE LA VM] apk add curl wget nano htop
VBoxManage snapshot "Lab5-Alpine" take "snap_con_herramientas" --description "Alpine con curl, wget, nano y htop instalados"
VBoxManage snapshot "Lab5-Alpine" list
# [DENTRO DE LA VM] poweroff
VBoxManage snapshot "Lab5-Alpine" restore "snap_base"
VBoxManage startvm "Lab5-Alpine" --type gui
# [DENTRO DE LA VM] which curl || echo "curl NO esta instalado"

# ---------------------------------------------------------------
# PASO 5 - Reasignacion de recursos (modifyvm, con la VM apagada)
# ---------------------------------------------------------------
# [DENTRO DE LA VM] poweroff
VBoxManage modifyvm "Lab5-Alpine" --cpus 2 --memory 2048 --ioapic on
VBoxManage startvm "Lab5-Alpine" --type gui
# [DENTRO DE LA VM] nproc
# [DENTRO DE LA VM] free -m

# ---------------------------------------------------------------
# PASO 6 - Disco de asignacion fija (4 GB) y benchmark contra el disco dinamico
# ---------------------------------------------------------------
# [DENTRO DE LA VM] poweroff
VBoxManage createmedium disk --filename "C:\Users\diego\VirtualBox VMs\Lab5-Alpine\Lab5-Alpine-fixed.vdi" --size 4096 --format VDI --variant Fixed
VBoxManage storageattach "Lab5-Alpine" --storagectl "SATA" --port 1 --device 0 --type hdd --medium "C:\Users\diego\VirtualBox VMs\Lab5-Alpine\Lab5-Alpine-fixed.vdi"
VBoxManage startvm "Lab5-Alpine" --type gui
# [DENTRO DE LA VM] apk add e2fsprogs
# [DENTRO DE LA VM] fdisk /dev/sdb              (n, p, 1, Enter, Enter, w)
# [DENTRO DE LA VM] mkfs.ext4 /dev/sdb1
# [DENTRO DE LA VM] mkdir /mnt/fijo
# [DENTRO DE LA VM] mount /dev/sdb1 /mnt/fijo
# [DENTRO DE LA VM] time dd if=/dev/zero of=/mnt/fijo/test.img bs=1M count=200 conv=fsync
# [DENTRO DE LA VM] time dd if=/dev/zero of=/root/test.img bs=1M count=200 conv=fsync
# [DENTRO DE LA VM] rm /mnt/fijo/test.img /root/test.img

# ---------------------------------------------------------------
# PASO 9 - Exportacion OVA (el .ova NO se sube al repositorio)
# ---------------------------------------------------------------
# [DENTRO DE LA VM] poweroff
VBoxManage export "Lab5-Alpine" --output "C:\Users\diego\VirtualBox VMs\Lab5-Alpine-export.ova" --manifest
dir "C:\Users\diego\VirtualBox VMs\Lab5-Alpine-export.ova"
# Importacion en otra instalacion: VBoxManage import Lab5-Alpine-export.ova
