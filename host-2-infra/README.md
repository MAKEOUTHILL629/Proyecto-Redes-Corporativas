# Host-SVR-02: Servidor de Infraestructura

## Especificaciones del Host

- **Sistema Operativo:** MacOS
- **Hardware:** MacBook Pro M4
- **Docker:** Docker Desktop para Mac
- **Hostname:** svr-infra.chispitas.local
- **IP LAN:** 192.168.1.20

## Servicios Desplegados

Este host ejecuta los servicios críticos de infraestructura de red:

### 1. Servidor de Correo (docker-mailserver)
- **IP:** 172.20.2.10
- **Hostname:** mail.chispitas.local
- **Puertos:** 25, 587, 465 (SMTP), 143, 993 (IMAP), 110, 995 (POP3)
- **Función:** Servidor de correo corporativo con integración LDAP
- **Autenticación:** LDAP contra FreeIPA

### 2. Servidor de Archivos (Samba)
- **IP:** 172.20.2.20
- **Hostname:** files.chispitas.local
- **Puertos:** 139, 445 (SMB/CIFS)
- **Función:** Servidor de archivos de red con recursos compartidos
- **Autenticación:** LDAP contra FreeIPA

### Recursos Compartidos (Shares) de Samba

| Share | Grupo con Acceso | Permisos | Descripción |
|-------|-----------------|----------|-------------|
| Produccion | GRP_Produccion | Lectura/Escritura | Archivos del área de producción |
| Comercial | GRP_Comercial | Lectura/Escritura | Archivos del área comercial |
| RRHH | GRP_RRHH | Lectura/Escritura | Archivos de recursos humanos |
| Gerencia | GRP_Gerencia | Lectura/Escritura | Documentos ejecutivos |
| Compartido | Todos los usuarios | Solo lectura (Admins: escritura) | Archivos compartidos de la empresa |
| homes | Usuario individual | Lectura/Escritura | Carpeta personal de cada usuario |

## Instrucciones de Despliegue

### Prerrequisitos

1. **Docker Desktop instalado:**
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Red Docker creada:**
   ```bash
   docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
   ```

3. **FreeIPA debe estar funcionando en Host-SVR-01:**
   - Verificar que FreeIPA sea accesible: `ping 192.168.1.10`
   - Verificar DNS: `dig @192.168.1.10 chispitas.local`

4. **Archivo .env configurado:**
   ```bash
   # Copiar el template desde la raíz del proyecto
   cp ../.env.template ../.env
   # Editar .env con las contraseñas
   nano ../.env
   ```

### Despliegue

1. **Abrir Terminal:**
   ```bash
   cd /ruta/al/proyecto/host-2-infra
   ```

2. **Iniciar los servicios:**
   ```bash
   docker-compose up -d
   ```

3. **Verificar el estado:**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

### Post-Instalación

#### 1. Configurar Servidor de Correo

El servidor de correo se autoconfigura con las variables de entorno del .env, pero necesita algunas configuraciones adicionales:

**Crear cuentas de correo (opcional si usa LDAP):**
```bash
# Entrar al contenedor
docker exec -it mailserver bash

# Agregar cuenta de correo manualmente (si es necesario)
setup email add postmaster@chispitas.local <contraseña>

# Listar cuentas
setup email list

# Verificar configuración LDAP
setup debug login klinares
```

**Probar envío de correo:**
```bash
# Desde el host
telnet localhost 25
EHLO mail.chispitas.local
QUIT

# O usando swaks (instalar primero)
brew install swaks
swaks --to klinares@chispitas.local --from test@chispitas.local --server localhost
```

#### 2. Configurar Samba y Unirse al Dominio

**Preparar directorios compartidos:**
```bash
# Entrar al contenedor de Samba
docker exec -it samba-server bash

# Verificar que los directorios existen
ls -la /shares/

# Crear directorios si no existen
mkdir -p /shares/{Produccion,Comercial,RRHH,Gerencia,Compartido}
chmod 770 /shares/*
```

**Configurar password LDAP:**
```bash
# Dentro del contenedor de Samba
smbpasswd -w <FREEIPA_ADMIN_PASSWORD>

# Probar conexión LDAP
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <FREEIPA_ADMIN_PASSWORD> \
  -b "cn=users,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixAccount)"
```

**Agregar usuarios de Samba:**

Para cada usuario de FreeIPA, debe agregarse también a Samba:
```bash
# Dentro del contenedor de Samba
smbpasswd -a klinares
# Ingresar la contraseña (misma que en FreeIPA)

smbpasswd -a lhernandez
smbpasswd -a jmolano
smbpasswd -a egonzales

# Listar usuarios
pdbedit -L -v
```

**Reiniciar Samba:**
```bash
# Desde el host
docker-compose restart samba
```

#### 3. Verificar Servicios

**Verificar Mail Server:**
```bash
# Ver logs
docker logs mailserver

# Probar puertos
nc -zv localhost 25    # SMTP
nc -zv localhost 587   # Submission
nc -zv localhost 143   # IMAP
nc -zv localhost 993   # IMAPS
```

**Verificar Samba:**
```bash
# Ver logs
docker logs samba-server

# Listar shares disponibles
smbclient -L localhost -U admin%<password>

# Conectar a un share
smbclient //localhost/Compartido -U admin%<password>
```

## Pruebas de Validación

### Prueba 1: Servidor de Correo

**Desde Host-SVR-03 (o cualquier cliente):**

1. **Configurar Thunderbird:**
   - Nombre: Luis Hernandez
   - Email: lhernandez@chispitas.local
   - Servidor entrante (IMAP): mail.chispitas.local, puerto 143
   - Servidor saliente (SMTP): mail.chispitas.local, puerto 587
   - Usuario: lhernandez
   - Contraseña: [contraseña de FreeIPA]

2. **Enviar correo de prueba:**
   - Crear nuevo mensaje
   - Para: jmolano@chispitas.local
   - Asunto: Prueba de correo Chispitas
   - Enviar

3. **Verificar recepción:**
   - Configurar segunda cuenta en Thunderbird para jmolano
   - Verificar que llegue el mensaje

### Prueba 2: Servidor de Archivos

**Desde Host-SVR-03 (Linux):**

```bash
# Instalar cliente Samba
sudo apt-get install smbclient cifs-utils

# Listar shares disponibles
smbclient -L //192.168.1.20 -U lhernandez
# O usando el nombre DNS:
smbclient -L //files.chispitas.local -U lhernandez

# Conectar al share de Producción (lhernandez tiene acceso)
smbclient //files.chispitas.local/Produccion -U lhernandez
> ls
> mkdir test_produccion
> put archivo_local.txt
> exit

# Intentar conectar a Comercial (debe fallar para lhernandez)
smbclient //files.chispitas.local/Comercial -U lhernandez
> mkdir test_comercial
# Debería mostrar: NT_STATUS_ACCESS_DENIED

# Conectar como jmolano (debe tener acceso a Comercial)
smbclient //files.chispitas.local/Comercial -U jmolano
> mkdir test_comercial
> exit
```

**Desde Windows:**
```powershell
# Mapear unidad de red
net use Z: \\files.chispitas.local\Produccion /user:lhernandez <password>

# Acceder a la unidad
explorer Z:
```

**Desde MacOS:**
```bash
# Conectar a share
open smb://lhernandez@files.chispitas.local/Produccion

# O desde Finder: Cmd+K
# smb://files.chispitas.local
```

## Comandos Útiles

### Mail Server

```bash
# Ver logs en tiempo real
docker logs -f mailserver

# Reiniciar servicio
docker-compose restart mailserver

# Ver cola de correos
docker exec mailserver postqueue -p

# Flush cola
docker exec mailserver postqueue -f

# Ver configuración de Postfix
docker exec mailserver postconf -n

# Ver configuración de Dovecot
docker exec mailserver doveconf -n

# Ver usuarios LDAP
docker exec mailserver setup debug login <username>
```

### Samba

```bash
# Ver logs
docker logs -f samba-server

# Reiniciar servicio
docker-compose restart samba

# Listar usuarios
docker exec samba-server pdbedit -L

# Ver conexiones activas
docker exec samba-server smbstatus

# Ver shares configurados
docker exec samba-server testparm -s

# Probar autenticación de usuario
docker exec samba-server smbclient -L localhost -U <username>
```

### Diagnóstico

```bash
# Verificar conectividad con FreeIPA
ping 192.168.1.10
dig @192.168.1.10 chispitas.local

# Probar LDAP
ldapsearch -x -H ldap://192.168.1.10 -b "dc=chispitas,dc=local"

# Verificar puertos abiertos
sudo lsof -i -P -n | grep LISTEN
sudo netstat -tulpn | grep -E "25|587|143|993|139|445"
```

## Troubleshooting

### Mail Server no recibe correos

1. Verificar que FreeIPA esté accesible:
   ```bash
   ping 192.168.1.10
   ldapsearch -x -H ldap://192.168.1.10 -b "dc=chispitas,dc=local"
   ```

2. Revisar logs:
   ```bash
   docker logs mailserver | grep -i error
   ```

3. Verificar configuración LDAP:
   ```bash
   docker exec mailserver setup debug login <username>
   ```

### Samba no autentica usuarios

1. Verificar que los usuarios existen en FreeIPA y Samba:
   ```bash
   docker exec samba-server pdbedit -L
   ```

2. Agregar usuarios si faltan:
   ```bash
   docker exec -it samba-server smbpasswd -a <username>
   ```

3. Verificar contraseña LDAP:
   ```bash
   docker exec -it samba-server smbpasswd -w <FREEIPA_ADMIN_PASSWORD>
   ```

4. Probar conexión LDAP:
   ```bash
   docker exec samba-server ldapsearch -x -H ldap://192.168.1.10 \
     -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
     -w <password> -b "dc=chispitas,dc=local"
   ```

### Permisos de archivos incorrectos

1. Verificar grupos en FreeIPA:
   - Los grupos deben existir: GRP_Produccion, GRP_Comercial, etc.

2. Ajustar permisos en contenedor:
   ```bash
   docker exec samba-server chmod -R 770 /shares/Produccion
   docker exec samba-server chown -R root:GRP_Produccion /shares/Produccion
   ```

## Recursos

- docker-mailserver: https://docker-mailserver.github.io/docker-mailserver/
- Samba Documentation: https://www.samba.org/samba/docs/
- FreeIPA LDAP: https://www.freeipa.org/page/HowTo/LDAP
