# Guía de Implementación Completa
## Proyecto: Intranet Corporativa "Chispitas: Fábrica de Momentos"

---

## Índice

1. [Visión General](#visión-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Preparación del Entorno](#preparación-del-entorno)
4. [Despliegue Paso a Paso](#despliegue-paso-a-paso)
5. [Configuración Post-Instalación](#configuración-post-instalación)
6. [Pruebas y Validación](#pruebas-y-validación)
7. [Troubleshooting](#troubleshooting)
8. [Mantenimiento](#mantenimiento)

---

## Visión General

Este documento describe la implementación completa de la intranet corporativa para "Chispitas: Fábrica de Momentos", una solución empresarial integrada basada en software Open Source y orquestada con Docker.

### Objetivos del Proyecto

- Migrar de procesos manuales a una plataforma empresarial integrada
- Implementar gestión centralizada de identidades (LDAP/Kerberos)
- Proveer servicios de correo corporativo
- Implementar servidor de archivos con permisos granulares
- Desplegar suite de aplicaciones de productividad (ERP/CRM/HRM)
- Establecer arquitectura de red segura y escalable

### Alcance

La implementación distribuye servicios en **tres hosts físicos** con diferentes sistemas operativos:

| Host | Sistema Operativo | Recursos | Servicios |
|------|-------------------|----------|-----------|
| Host-SVR-01 | Windows 11 (WSL2) | Ryzen 5 7600x, 32GB RAM | FreeIPA, Odoo, SuiteCRM, OrangeHRM, Dolibarr |
| Host-SVR-02 | MacOS (M4) | Memoria >16GB | Servidor de Correo, Samba |
| Host-SVR-03 | Lubuntu | AMD E1, 4GB RAM | Traefik, Cliente de Pruebas |

---

## Arquitectura del Sistema

### Diagrama de Red

```
                          Internet
                             |
                        [Router LAN]
                             |
                   192.168.1.0/24 (Red LAN)
                             |
       +---------------------+---------------------+
       |                     |                     |
  Host-SVR-01           Host-SVR-02           Host-SVR-03
  192.168.1.10          192.168.1.20          192.168.1.30
  (Windows/WSL2)        (MacOS)               (Lubuntu)
       |                     |                     |
  chispitas_net         chispitas_net         chispitas_net
  172.20.0.0/16         172.20.0.0/16         172.20.0.0/16
       |                     |                     |
  +----+----+           +----+----+           +----+----+
  |         |           |         |           |         |
FreeIPA   Apps      Mail Srv   Samba      Traefik   Test
Odoo      CRM       Postfix    Files      Proxy     Client
SuiteCRM  HRM       Dovecot                          
OrangeHRM ERP
Dolibarr
```

### Flujo de Servicios

1. **DNS:** Todos los hosts apuntan a FreeIPA (192.168.1.10) para resolución DNS
2. **Autenticación:** FreeIPA provee autenticación centralizada via LDAP/Kerberos
3. **Acceso Web:** Traefik en Host-SVR-03 actúa como punto de entrada único
4. **Correo:** Servidor de correo en Host-SVR-02 usa LDAP para autenticación
5. **Archivos:** Samba en Host-SVR-02 integrado con FreeIPA para permisos

---

## Preparación del Entorno

### Requisitos Previos

#### Todos los Hosts

1. **Conectividad de Red:**
   - Todos los hosts en la misma red LAN (192.168.1.0/24)
   - IPs estáticas asignadas (recomendado)
   - Conectividad entre hosts verificada

2. **Docker Instalado:**
   - Docker Engine (Linux) o Docker Desktop (Windows/Mac)
   - Docker Compose versión 1.29 o superior
   - Usuario con permisos para ejecutar Docker

3. **Sincronización de Tiempo:**
   - Todos los hosts con hora sincronizada (crítico para Kerberos)
   - NTP configurado

#### Host-SVR-01 (Windows)

```powershell
# Verificar WSL2
wsl --list --verbose

# Verificar Docker Desktop
docker --version
docker-compose --version

# Configurar IP estática (en configuración de red de Windows)
# IP: 192.168.1.10
# Gateway: 192.168.1.1
# DNS: 8.8.8.8 (temporal, cambiará a 192.168.1.10 después)
```

#### Host-SVR-02 (MacOS)

```bash
# Verificar Docker Desktop
docker --version
docker-compose --version

# Configurar IP estática (System Preferences → Network)
# IP: 192.168.1.20
# Gateway: 192.168.1.1
# DNS: 8.8.8.8 (temporal)

# Instalar herramientas adicionales
brew install wget curl
```

#### Host-SVR-03 (Lubuntu)

```bash
# Actualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Instalar Docker
sudo apt-get install docker.io docker-compose -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Configurar IP estática (editar /etc/netplan/*.yaml)
# IP: 192.168.1.30
# Gateway: 192.168.1.1
# DNS: 8.8.8.8 (temporal)

# Instalar herramientas de cliente
sudo apt-get install thunderbird smbclient cifs-utils \
  dnsutils ldap-utils curl wget net-tools -y
```

### Clonar el Repositorio

En **todos los hosts**, clonar el repositorio:

```bash
# Linux/Mac
cd ~
git clone <url-del-repositorio>
cd Proyecto-Redes-Corporativas

# Windows (PowerShell)
cd C:\Users\<usuario>
git clone <url-del-repositorio>
cd Proyecto-Redes-Corporativas
```

### Configurar Variables de Entorno

```bash
# Copiar template
cp .env.template .env

# Editar archivo .env
nano .env  # Linux/Mac
notepad .env  # Windows
```

**Configuraciones críticas a revisar en .env:**

- `HOST_SVR_01_IP=192.168.1.10` - Ajustar según su red
- `HOST_SVR_02_IP=192.168.1.20` - Ajustar según su red
- `HOST_SVR_03_IP=192.168.1.30` - Ajustar según su red
- `FREEIPA_ADMIN_PASSWORD` - Cambiar contraseña segura
- `FREEIPA_DM_PASSWORD` - Cambiar contraseña segura
- Todas las contraseñas de bases de datos
- Todas las contraseñas de aplicaciones

---

## Despliegue Paso a Paso

### Paso 1: Crear Redes Docker

**En cada host**, ejecutar:

```bash
docker network create --driver bridge \
  --subnet=172.20.0.0/16 \
  --gateway=172.20.0.1 \
  chispitas_net

# Verificar
docker network ls
docker network inspect chispitas_net
```

### Paso 2: Desplegar Host-SVR-01 (FreeIPA y Aplicaciones)

**En Host-SVR-01 (Windows):**

```powershell
# Navegar al directorio
cd host-1-powerhouse

# Iniciar servicios
docker-compose up -d

# Verificar estado
docker-compose ps

# Seguir logs de FreeIPA (esperar ~5-10 minutos para primera instalación)
docker logs -f freeipa-server

# Esperar mensaje: "FreeIPA server configured."
# Presionar Ctrl+C para salir de los logs
```

**Verificar que FreeIPA está funcionando:**

```powershell
# Desde PowerShell o WSL2
curl -k https://localhost
# Debe mostrar HTML de FreeIPA

# Verificar DNS
docker exec freeipa-server dig chispitas.local
```

### Paso 3: Configurar FreeIPA (Poblamiento)

**Acceder al contenedor de FreeIPA:**

```bash
# Desde WSL2 o PowerShell
docker exec -it freeipa-server /bin/bash
```

**Dentro del contenedor:**

```bash
# Autenticarse como admin
kinit admin
# Ingresar contraseña (valor de FREEIPA_ADMIN_PASSWORD del .env)

# Ejecutar script de poblamiento
chmod +x /setup_chispitas.sh
/setup_chispitas.sh

# El script creará:
# - Grupos de seguridad
# - Usuarios de prueba
# - Registros DNS
# - Políticas del dominio

# Verificar usuarios creados
ipa user-find

# Verificar grupos
ipa group-find

# Verificar DNS
ipa dnsrecord-find chispitas.local

# Salir del contenedor
exit
```

### Paso 4: Configurar DNS en Hosts

**Host-SVR-01 (Windows WSL2):**

```bash
# En WSL2
sudo nano /etc/resolv.conf

# Agregar al inicio:
nameserver 192.168.1.10
nameserver 8.8.8.8
```

**Host-SVR-02 (MacOS):**

```bash
# Crear resolver para el dominio
sudo mkdir -p /etc/resolver
sudo bash -c 'echo "nameserver 192.168.1.10" > /etc/resolver/chispitas.local'

# Verificar
scutil --dns
```

**Host-SVR-03 (Lubuntu):**

```bash
# Método 1: Editar resolv.conf (temporal)
sudo nano /etc/resolv.conf
# Agregar:
# nameserver 192.168.1.10

# Método 2: Usar systemd-resolved (permanente)
sudo nano /etc/systemd/resolved.conf
# Descomentar y configurar:
# [Resolve]
# DNS=192.168.1.10
# Domains=chispitas.local

sudo systemctl restart systemd-resolved

# Verificar
resolvectl status
```

**Probar resolución DNS desde cualquier host:**

```bash
dig odoo.chispitas.local
dig -t MX chispitas.local
nslookup mail.chispitas.local
```

### Paso 5: Desplegar Host-SVR-02 (Correo y Archivos)

**En Host-SVR-02 (MacOS):**

```bash
cd host-2-infra

# Iniciar servicios
docker-compose up -d

# Verificar estado
docker-compose ps

# Ver logs
docker logs -f mailserver
# Presionar Ctrl+C para salir

docker logs -f samba-server
```

**Configurar Servidor de Correo:**

```bash
# Acceder al contenedor
docker exec -it mailserver bash

# El servidor ya está configurado con LDAP via variables de entorno
# Probar autenticación LDAP de un usuario
setup debug login lhernandez
# Debe mostrar información del usuario de FreeIPA

exit
```

**Configurar Samba:**

```bash
# Acceder al contenedor
docker exec -it samba-server bash

# Configurar contraseña LDAP
smbpasswd -w <FREEIPA_ADMIN_PASSWORD>

# Agregar usuarios de Samba (mismo password que en FreeIPA)
smbpasswd -a klinares
# Ingresar password: User1Pass2024!

smbpasswd -a lhernandez
# Ingresar password: User2Pass2024!

smbpasswd -a jmolano
# Ingresar password: User3Pass2024!

smbpasswd -a egonzales
# Ingresar password: User4Pass2024!

# Verificar usuarios
pdbedit -L

# Crear directorios si no existen
mkdir -p /shares/{Produccion,Comercial,RRHH,Gerencia,Compartido}
chmod 770 /shares/*

# Reiniciar Samba
exit
docker-compose restart samba
```

### Paso 6: Desplegar Host-SVR-03 (Proxy y Cliente)

**En Host-SVR-03 (Lubuntu):**

```bash
cd host-3-edge

# Iniciar Traefik
docker-compose up -d

# Verificar estado
docker-compose ps

# Ver logs
docker logs -f traefik
```

**Acceder al Dashboard de Traefik:**

```bash
firefox http://localhost:8080 &
# O
firefox http://traefik.chispitas.local &
```

### Paso 7: Verificación Inicial

**Desde Host-SVR-03 (o cualquier host):**

```bash
# Probar resolución DNS
dig odoo.chispitas.local
dig crm.chispitas.local
dig mail.chispitas.local
dig -t MX chispitas.local

# Probar acceso a servicios web
curl -I http://odoo.chispitas.local
curl -I http://crm.chispitas.local
curl -I http://hrm.chispitas.local
curl -I http://erp.chispitas.local

# Abrir en navegador
firefox http://odoo.chispitas.local &
firefox http://crm.chispitas.local &
```

---

## Configuración Post-Instalación

### Configurar Odoo

1. Acceder a http://odoo.chispitas.local
2. Completar wizard de instalación:
   - Master Password: (valor de ODOO_MASTER_PASSWORD)
   - Database Name: odoo_db
   - Email: admin@chispitas.local
   - Password: crear contraseña segura
   - Country: Colombia
   - Demo data: No

### Configurar SuiteCRM

1. Acceder a http://crm.chispitas.local
2. Login con credenciales del .env
3. Configurar LDAP (opcional):
   - Admin → LDAP Settings
   - Server: ipa.chispitas.local
   - Port: 389
   - Base DN: cn=users,cn=accounts,dc=chispitas,dc=local

### Configurar OrangeHRM

1. Acceder a http://hrm.chispitas.local
2. Completar wizard de instalación
3. Configurar conexión a base de datos (ya configurada via Docker)

### Configurar Dolibarr

1. Acceder a http://erp.chispitas.local
2. Completar wizard de instalación
3. Configurar módulos necesarios

---

## Pruebas y Validación

Ver el archivo `host-3-edge/README.md` para el plan completo de auditoría y validación.

### Resumen de Pruebas Clave

1. **DNS:** Todos los nombres resuelven correctamente
2. **Correo:** Envío/recepción entre usuarios funciona
3. **Archivos:** Permisos granulares basados en grupos funcionan correctamente
4. **Web:** Todas las aplicaciones accesibles via proxy
5. **LDAP:** Autenticación centralizada funciona

---

## Troubleshooting

Ver archivos README.md de cada host para troubleshooting específico.

### Problemas Comunes

#### DNS no resuelve
- Verificar que FreeIPA esté corriendo
- Verificar /etc/resolv.conf apunta a 192.168.1.10
- Limpiar cache DNS

#### Aplicaciones no accesibles
- Verificar que contenedores están corriendo: `docker ps`
- Verificar logs: `docker logs <container>`
- Verificar conectividad de red entre hosts

#### Samba no autentica
- Verificar usuarios agregados con smbpasswd
- Verificar contraseña LDAP configurada
- Verificar conectividad con FreeIPA

---

## Mantenimiento

### Backups

```bash
# Backup de FreeIPA (crítico)
docker run --rm \
  -v host-1-powerhouse_freeipa_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/freeipa-$(date +%Y%m%d).tar.gz /data

# Backup de bases de datos
docker exec postgres-odoo pg_dump -U odoo_user odoo_db > backup-odoo.sql
```

### Actualizaciones

```bash
# Actualizar imágenes
docker-compose pull
docker-compose up -d

# Ver logs para verificar
docker-compose logs -f
```

### Monitoreo

```bash
# Ver uso de recursos
docker stats

# Ver logs en tiempo real
docker-compose logs -f

# Verificar salud de servicios
docker ps
```

---

## Conclusión

Esta guía proporciona todos los pasos necesarios para desplegar y operar la intranet corporativa de Chispitas. Para soporte adicional, consulte:

- Documentación individual de cada host (README.md)
- Documentación de configuración de red (docs/NETWORK_CONFIGURATION.md)
- Recursos de las tecnologías utilizadas (enlaces en cada README)

**Autores:** Grupo 3-302 - Proyecto de Redes Corporativas
- Kevin Justinn Linares Romero
- Luis Felipe Hernández Chica
- Jhon Fredy Molano Galindo
- Eber Santiago Gonzales Castillo
