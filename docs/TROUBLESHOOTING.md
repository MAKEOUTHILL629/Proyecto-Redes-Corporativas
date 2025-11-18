# Troubleshooting Guide
## Proyecto Chispitas - Resolución de Problemas

Esta guía proporciona soluciones a los problemas más comunes que pueden surgir durante el despliegue y operación de la infraestructura.

---

## Índice

1. [Problemas de Docker](#problemas-de-docker)
2. [Problemas de Red](#problemas-de-red)
3. [Problemas de DNS](#problemas-de-dns)
4. [Problemas de FreeIPA](#problemas-de-freeipa)
5. [Problemas del Servidor de Correo](#problemas-del-servidor-de-correo)
6. [Problemas de Samba](#problemas-de-samba)
7. [Problemas de Traefik](#problemas-de-traefik)
8. [Problemas de Aplicaciones Web](#problemas-de-aplicaciones-web)
9. [Problemas de Rendimiento](#problemas-de-rendimiento)

---

## Problemas de Docker

### Problema: Docker no inicia

**Síntomas:**
```bash
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solución:**

```bash
# Linux
sudo systemctl status docker
sudo systemctl start docker
sudo systemctl enable docker

# Verificar usuario en grupo docker
groups $USER
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar

# Windows/Mac
# Abrir Docker Desktop y verificar que está ejecutándose
```

---

### Problema: Red Docker no existe

**Síntomas:**
```bash
ERROR: Network chispitas_net declared as external, but could not be found
```

**Solución:**

```bash
# Crear la red
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net

# Verificar
docker network ls
docker network inspect chispitas_net
```

---

### Problema: Conflicto de puertos

**Síntomas:**
```bash
Error starting userland proxy: listen tcp 0.0.0.0:80: bind: address already in use
```

**Solución:**

```bash
# Identificar proceso usando el puerto
sudo lsof -i :80
# O
sudo netstat -tulpn | grep :80

# Detener el proceso
sudo kill -9 <PID>

# O cambiar el puerto en docker-compose.yml
# En lugar de "80:80", usar "8080:80"
```

---

### Problema: Volúmenes con permisos incorrectos

**Síntomas:**
- Contenedor no puede escribir en volúmenes
- Errores de "Permission denied"

**Solución:**

```bash
# Identificar el volumen
docker volume ls
docker volume inspect <volume_name>

# Verificar permisos (en el host)
sudo ls -la /var/lib/docker/volumes/<volume_name>/_data

# Ajustar permisos
sudo chmod -R 755 /var/lib/docker/volumes/<volume_name>/_data
sudo chown -R 1000:1000 /var/lib/docker/volumes/<volume_name>/_data

# Reiniciar contenedor
docker-compose restart <service>
```

---

## Problemas de Red

### Problema: Hosts no se comunican

**Síntomas:**
- `ping` entre hosts falla
- Servicios no accesibles desde otros hosts

**Diagnóstico:**

```bash
# Verificar conectividad básica
ping 192.168.1.10
ping 192.168.1.20
ping 192.168.1.30

# Verificar ruta
traceroute 192.168.1.10

# Verificar interfaz de red
ip addr show
# O en Mac/Windows
ifconfig
ipconfig
```

**Solución:**

```bash
# Verificar que todos los hosts están en la misma subred
# Ejemplo: 192.168.1.0/24

# Verificar gateway
ip route show
# Debe mostrar: default via 192.168.1.1 dev <interface>

# Verificar firewall
# Linux
sudo ufw status
sudo ufw allow from 192.168.1.0/24

# Windows
# Firewall de Windows → Agregar regla para 192.168.1.0/24

# Mac
# System Preferences → Security & Privacy → Firewall → Firewall Options
```

---

### Problema: Contenedores no alcanzan internet

**Síntomas:**
- `docker exec <container> ping 8.8.8.8` falla
- Contenedores no pueden descargar paquetes

**Solución:**

```bash
# Verificar DNS del host
cat /etc/resolv.conf

# Verificar que Docker puede hacer NAT
sudo iptables -t nat -L -n

# Reiniciar Docker
sudo systemctl restart docker

# Verificar configuración de Docker
cat /etc/docker/daemon.json
# Debe contener:
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}

sudo systemctl restart docker
```

---

## Problemas de DNS

### Problema: DNS no resuelve nombres del dominio

**Síntomas:**
```bash
$ dig odoo.chispitas.local
;; connection timed out; no servers could be reached
```

**Diagnóstico:**

```bash
# Verificar que FreeIPA está corriendo
docker ps | grep freeipa
docker logs freeipa-server | tail -50

# Verificar puerto DNS
sudo netstat -tulpn | grep :53
nc -zv 192.168.1.10 53

# Probar resolución directa
dig @192.168.1.10 chispitas.local
```

**Solución:**

```bash
# Verificar /etc/resolv.conf
cat /etc/resolv.conf
# Debe contener: nameserver 192.168.1.10

# Editar si es necesario
sudo nano /etc/resolv.conf
# Agregar al inicio:
nameserver 192.168.1.10

# Para hacer permanente (systemd-resolved)
sudo nano /etc/systemd/resolved.conf
# [Resolve]
# DNS=192.168.1.10
# Domains=chispitas.local

sudo systemctl restart systemd-resolved

# Verificar
resolvectl status
```

---

### Problema: Resolución lenta o intermitente

**Síntomas:**
- Comandos `dig` tardan mucho
- Algunas consultas fallan aleatoriamente

**Solución:**

```bash
# Agregar DNS secundario
sudo nano /etc/resolv.conf
nameserver 192.168.1.10
nameserver 8.8.8.8

# Limpiar cache DNS
# Linux
sudo systemd-resolve --flush-caches
# Mac
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
# Windows
ipconfig /flushdns

# Verificar latencia DNS
time dig odoo.chispitas.local
```

---

## Problemas de FreeIPA

### Problema: FreeIPA no inicia o se reinicia constantemente

**Síntomas:**
```bash
$ docker ps -a | grep freeipa
freeipa-server   Restarting
```

**Diagnóstico:**

```bash
# Ver logs
docker logs freeipa-server

# Verificar espacio en disco
df -h

# Verificar memoria RAM
free -h

# Verificar capabilities
docker inspect freeipa-server | grep -A 10 CapAdd
```

**Solución:**

```bash
# FreeIPA requiere mínimo 2GB RAM
# Verificar que el host tiene suficiente memoria

# Verificar que las capabilities están configuradas
# En docker-compose.yml debe tener:
cap_add:
  - SYS_TIME
  - NET_ADMIN

# Reiniciar contenedor
docker-compose down
docker-compose up -d

# Si persiste, eliminar volúmenes y reinstalar
docker-compose down -v
docker volume rm host-1-powerhouse_freeipa_data
docker-compose up -d
```

---

### Problema: No puedo autenticarme en FreeIPA

**Síntomas:**
```bash
$ kinit admin
kinit: Password incorrect while getting initial credentials
```

**Solución:**

```bash
# Verificar que está usando la contraseña correcta del .env
cat ../.env | grep FREEIPA_ADMIN_PASSWORD

# Reset de contraseña del admin (si es necesario)
docker exec -it freeipa-server bash
ipa-passwd admin
# Ingresar nueva contraseña

# Verificar tickets Kerberos
klist

# Limpiar tickets antiguos
kdestroy -A
```

---

### Problema: Usuarios o grupos no aparecen

**Síntomas:**
- `ipa user-find` no muestra usuarios esperados
- `ipa group-find` no muestra grupos

**Solución:**

```bash
# Acceder al contenedor
docker exec -it freeipa-server bash

# Autenticarse
kinit admin

# Re-ejecutar script de poblamiento
chmod +x /setup_chispitas.sh
/setup_chispitas.sh

# Verificar creación manual
ipa user-add testuser --first=Test --last=User --email=test@chispitas.local --password

# Verificar en LDAP directamente
ldapsearch -x -H ldap://localhost \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <password> \
  -b "cn=users,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixAccount)"
```

---

## Problemas del Servidor de Correo

### Problema: No puede enviar correos

**Síntomas:**
- Thunderbird muestra error al enviar
- Logs muestran rechazo de relay

**Diagnóstico:**

```bash
# Ver logs del servidor de correo
docker logs mailserver | tail -100

# Verificar puertos
nc -zv 192.168.1.20 25
nc -zv 192.168.1.20 587

# Probar SMTP manualmente
telnet 192.168.1.20 25
EHLO test
QUIT
```

**Solución:**

```bash
# Verificar configuración LDAP
docker exec mailserver setup debug login <username>

# Verificar que el usuario existe en FreeIPA
docker exec freeipa-server ipa user-show <username>

# Revisar configuración de Postfix
docker exec mailserver postconf -n | grep relay

# Verificar que la red está permitida
docker exec mailserver postconf mynetworks
# Debe incluir: 192.168.1.0/24 172.20.0.0/16

# Reiniciar servicio
docker-compose restart mailserver
```

---

### Problema: No recibe correos

**Síntomas:**
- Correos enviados pero no aparecen en bandeja de entrada
- IMAP no muestra mensajes

**Solución:**

```bash
# Verificar cola de correos
docker exec mailserver postqueue -p

# Procesar cola
docker exec mailserver postqueue -f

# Verificar logs de Dovecot
docker logs mailserver | grep dovecot

# Verificar autenticación IMAP
docker exec mailserver doveadm auth test <username> <password>

# Verificar que el buzón existe
docker exec mailserver ls -la /var/mail/<username>
```

---

### Problema: Autenticación LDAP falla

**Síntomas:**
```bash
setup debug login <username>
ERROR: Authentication failed
```

**Solución:**

```bash
# Verificar conectividad con FreeIPA
docker exec mailserver ping 192.168.1.10

# Probar consulta LDAP
docker exec mailserver ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <password> \
  -b "cn=users,cn=accounts,dc=chispitas,dc=local" \
  "(uid=<username>)"

# Verificar variables de entorno
docker exec mailserver env | grep LDAP

# Reiniciar con configuración actualizada
docker-compose down
docker-compose up -d
```

---

## Problemas de Samba

### Problema: No puede conectar a shares

**Síntomas:**
```bash
$ smbclient -L //files.chispitas.local -U lhernandez
session setup failed: NT_STATUS_LOGON_FAILURE
```

**Diagnóstico:**

```bash
# Verificar que Samba está corriendo
docker ps | grep samba
docker logs samba-server

# Verificar puerto
nc -zv 192.168.1.20 445

# Verificar usuarios Samba
docker exec samba-server pdbedit -L
```

**Solución:**

```bash
# Agregar usuario a Samba
docker exec -it samba-server bash
smbpasswd -a lhernandez
# Ingresar contraseña (misma que FreeIPA: User2Pass2024!)

# Verificar
pdbedit -L -v lhernandez

# Probar autenticación
smbclient -L localhost -U lhernandez

exit

# Reiniciar Samba
docker-compose restart samba
```

---

### Problema: Permisos incorrectos en shares

**Síntomas:**
- Usuario puede acceder a shares que no debería
- Usuario no puede escribir donde debería poder

**Solución:**

```bash
# Verificar configuración de Samba
docker exec samba-server testparm -s

# Verificar grupos en FreeIPA
docker exec freeipa-server ipa group-show GRP_Produccion
docker exec freeipa-server ipa group-show GRP_Comercial

# Verificar membresía de usuario
docker exec freeipa-server ipa user-show lhernandez --all | grep memberof

# Ajustar permisos de directorios
docker exec samba-server chmod -R 770 /shares/Produccion
docker exec samba-server chmod -R 770 /shares/Comercial

# Reiniciar Samba
docker-compose restart samba
```

---

### Problema: LDAP integration no funciona

**Síntomas:**
- Samba no encuentra usuarios de FreeIPA
- Autenticación falla incluso con password correcto

**Solución:**

```bash
# Verificar contraseña LDAP configurada
docker exec -it samba-server bash

# Reconfigurar
smbpasswd -w <FREEIPA_ADMIN_PASSWORD>

# Probar conexión LDAP
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <password> \
  -b "cn=users,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixAccount)"

# Verificar smb.conf
cat /etc/samba/smb.conf | grep ldap

exit

# Reiniciar Samba
docker-compose restart samba
```

---

## Problemas de Traefik

### Problema: Dashboard no accesible

**Síntomas:**
- http://localhost:8080 no responde
- Connection refused

**Solución:**

```bash
# Verificar que Traefik está corriendo
docker ps | grep traefik
docker logs traefik

# Verificar puerto
nc -zv localhost 8080

# Verificar configuración
docker exec traefik cat /etc/traefik/traefik.yml

# Reiniciar
docker-compose restart traefik
```

---

### Problema: Rutas no funcionan

**Síntomas:**
- http://odoo.chispitas.local retorna 404
- Gateway Timeout

**Diagnóstico:**

```bash
# Ver logs de Traefik
docker logs traefik | grep -i error

# Verificar configuración dinámica
docker exec traefik cat /etc/traefik/dynamic/services.yml

# Probar backend directamente
curl -I http://192.168.1.10:8069
```

**Solución:**

```bash
# Verificar que el backend está accesible
ping 192.168.1.10
curl -I http://192.168.1.10:8069

# Verificar DNS
dig odoo.chispitas.local
# Debe retornar 192.168.1.30 (IP del proxy)

# Editar configuración si es necesario
nano host-3-edge/config/traefik/dynamic/services.yml

# Reiniciar Traefik
docker-compose restart traefik

# Verificar en dashboard
firefox http://localhost:8080 &
# Ver sección HTTP > Routers y Services
```

---

## Problemas de Aplicaciones Web

### Problema: Odoo no inicia

**Síntomas:**
```bash
docker logs odoo-manufacturing
ERROR: could not connect to server: Connection refused
```

**Solución:**

```bash
# Verificar que PostgreSQL está corriendo y healthy
docker ps | grep postgres
docker logs postgres-odoo

# Verificar conectividad
docker exec odoo-manufacturing ping postgres-odoo

# Verificar variables de entorno
docker exec odoo-manufacturing env | grep -E "HOST|USER|PASSWORD"

# Reiniciar en orden
docker-compose restart postgres-odoo
sleep 10
docker-compose restart odoo
```

---

### Problema: SuiteCRM muestra error 500

**Síntomas:**
- Página muestra "Internal Server Error"
- No se puede acceder a la interfaz

**Solución:**

```bash
# Ver logs
docker logs suitecrm

# Verificar base de datos
docker exec mariadb-crm mysql -u root -p<password> -e "SHOW DATABASES;"

# Verificar permisos
docker exec mariadb-crm mysql -u root -p<password> -e "SHOW GRANTS FOR 'suitecrm_user'@'%';"

# Limpiar cache de SuiteCRM
docker exec suitecrm rm -rf /bitnami/suitecrm/cache/*

# Reiniciar
docker-compose restart mariadb-crm suitecrm
```

---

## Problemas de Rendimiento

### Problema: Sistema muy lento

**Diagnóstico:**

```bash
# Ver uso de recursos
docker stats

# Ver procesos
top
htop

# Ver espacio en disco
df -h

# Ver uso de red
iftop
nethogs
```

**Solución:**

```bash
# Limitar recursos de contenedores (en docker-compose.yml)
services:
  odoo:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G

# Limpiar contenedores y volúmenes no usados
docker system prune -a
docker volume prune

# Reiniciar servicios no críticos
docker-compose stop orangehrm dolibarr
```

---

## Herramientas de Diagnóstico

### Comandos Útiles

```bash
# Ver todos los contenedores
docker ps -a

# Ver logs de todos los servicios
docker-compose logs -f

# Ver uso de recursos
docker stats --no-stream

# Inspeccionar contenedor
docker inspect <container>

# Inspeccionar red
docker network inspect chispitas_net

# Inspeccionar volumen
docker volume inspect <volume>

# Ejecutar comando en contenedor
docker exec -it <container> /bin/bash

# Ver configuración de Docker Compose
docker-compose config

# Validar configuración
docker-compose config --quiet
```

### Scripts de Diagnóstico

```bash
# Script de verificación completa
cat > check_status.sh <<'EOF'
#!/bin/bash
echo "=== Estado de Contenedores ==="
docker ps -a

echo -e "\n=== Estado de Redes ==="
docker network ls

echo -e "\n=== Estado de Volúmenes ==="
docker volume ls

echo -e "\n=== Conectividad entre Hosts ==="
ping -c 2 192.168.1.10
ping -c 2 192.168.1.20
ping -c 2 192.168.1.30

echo -e "\n=== Resolución DNS ==="
dig chispitas.local +short
dig odoo.chispitas.local +short
dig mail.chispitas.local +short

echo -e "\n=== Servicios Activos ==="
nc -zv 192.168.1.10 80 2>&1 | grep succeeded
nc -zv 192.168.1.10 443 2>&1 | grep succeeded
nc -zv 192.168.1.20 25 2>&1 | grep succeeded
nc -zv 192.168.1.20 445 2>&1 | grep succeeded
nc -zv 192.168.1.30 80 2>&1 | grep succeeded
EOF

chmod +x check_status.sh
./check_status.sh
```

---

## Contacto y Soporte

Si el problema persiste después de seguir esta guía:

1. Revise los logs detallados: `docker logs <container> > logs.txt`
2. Ejecute el script de diagnóstico
3. Documente el problema con capturas de pantalla
4. Consulte la documentación oficial de cada componente
5. Busque en issues de GitHub de cada proyecto

**Recursos Adicionales:**

- FreeIPA: https://www.freeipa.org/page/Troubleshooting
- docker-mailserver: https://docker-mailserver.github.io/docker-mailserver/edge/faq/
- Samba: https://wiki.samba.org/index.php/Troubleshooting
- Traefik: https://doc.traefik.io/traefik/operations/troubleshooting/
