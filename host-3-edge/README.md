# Host-SVR-03: Servidor de Borde y Pruebas

## Especificaciones del Host

- **Sistema Operativo:** Lubuntu (Ubuntu ligero)
- **Hardware:** AMD E1, 4GB RAM
- **Docker:** Docker Engine (nativo)
- **Hostname:** svr-edge.chispitas.local
- **IP LAN:** 192.168.1.30

## Servicios Desplegados

Este host ejecuta el proxy inverso y sirve como estación de pruebas/auditoría:

### 1. Traefik Reverse Proxy
- **IP:** 172.20.3.10
- **Puertos:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Función:** Punto de entrada único para todos los servicios web
- **Dashboard:** http://192.168.1.30:8080 o http://traefik.chispitas.local

### 2. Cliente de Pruebas
Este host también funciona como estación de pruebas para validar toda la infraestructura.

**Software de Cliente Instalado:**
- Thunderbird (cliente de correo)
- smbclient (acceso a archivos compartidos)
- Navegador web
- Herramientas de red: dig, nslookup, ldapsearch, etc.

## Rutas Configuradas en Traefik

| Dominio | Destino | Servicio | Host |
|---------|---------|----------|------|
| odoo.chispitas.local | http://192.168.1.10:8069 | Odoo Manufacturing | Host-SVR-01 |
| crm.chispitas.local | http://192.168.1.10:8081 | SuiteCRM | Host-SVR-01 |
| hrm.chispitas.local | http://192.168.1.10:8082 | OrangeHRM | Host-SVR-01 |
| erp.chispitas.local | http://192.168.1.10:8083 | Dolibarr | Host-SVR-01 |
| ipa.chispitas.local | https://192.168.1.10 | FreeIPA | Host-SVR-01 |
| traefik.chispitas.local | Dashboard | Traefik | Host-SVR-03 |

## Instrucciones de Despliegue

### Prerrequisitos

1. **Docker instalado:**
   ```bash
   docker --version
   docker-compose --version
   ```
   
   Si no está instalado:
   ```bash
   sudo apt-get update
   sudo apt-get install docker.io docker-compose
   sudo systemctl enable docker
   sudo systemctl start docker
   sudo usermod -aG docker $USER
   # Cerrar sesión y volver a entrar
   ```

2. **Red Docker creada:**
   ```bash
   docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
   ```

3. **Verificar conectividad con otros hosts:**
   ```bash
   ping 192.168.1.10  # Host-SVR-01
   ping 192.168.1.20  # Host-SVR-02
   ```

4. **Configurar DNS:**
   ```bash
   # Apuntar a FreeIPA para resolución DNS
   sudo nano /etc/resolv.conf
   ```
   Agregar al inicio:
   ```
   nameserver 192.168.1.10
   nameserver 8.8.8.8
   ```
   
   Para hacerlo permanente:
   ```bash
   sudo nano /etc/systemd/resolved.conf
   ```
   Agregar:
   ```
   [Resolve]
   DNS=192.168.1.10
   Domains=chispitas.local
   ```
   Reiniciar:
   ```bash
   sudo systemctl restart systemd-resolved
   ```

### Despliegue

1. **Navegar al directorio:**
   ```bash
   cd /ruta/al/proyecto/host-3-edge
   ```

2. **Iniciar Traefik:**
   ```bash
   docker-compose up -d
   ```

3. **Verificar estado:**
   ```bash
   docker-compose ps
   docker-compose logs -f traefik
   ```

4. **Acceder al Dashboard:**
   ```bash
   firefox http://localhost:8080 &
   # O
   firefox http://traefik.chispitas.local &
   ```

## Configuración del Cliente de Pruebas

### 1. Instalar Software de Cliente

```bash
# Actualizar sistema
sudo apt-get update

# Cliente de correo
sudo apt-get install thunderbird

# Cliente SMB/CIFS
sudo apt-get install smbclient cifs-utils

# Herramientas de red y diagnóstico
sudo apt-get install dnsutils ldap-utils curl wget net-tools

# Navegador (si no está instalado)
sudo apt-get install firefox
```

### 2. Configurar /etc/hosts (Temporal)

Mientras DNS no esté completamente configurado:

```bash
sudo nano /etc/hosts
```

Agregar:
```
192.168.1.10    ipa.chispitas.local svr-powerhouse.chispitas.local
192.168.1.10    odoo.chispitas.local crm.chispitas.local hrm.chispitas.local erp.chispitas.local
192.168.1.20    mail.chispitas.local files.chispitas.local svr-infra.chispitas.local
192.168.1.30    traefik.chispitas.local svr-edge.chispitas.local
```

### 3. Configurar Thunderbird (Cliente de Correo)

**Cuenta 1 - Luis Hernández (Producción):**

1. Abrir Thunderbird
2. Crear cuenta nueva
   - Nombre: Luis Hernández
   - Email: lhernandez@chispitas.local
   - Contraseña: [contraseña de FreeIPA]
3. Configuración manual:
   - **IMAP:** mail.chispitas.local, puerto 143, STARTTLS
   - **SMTP:** mail.chispitas.local, puerto 587, STARTTLS
   - Usuario: lhernandez
   - Autenticación: Normal password

**Cuenta 2 - Jhon Molano (Comercial):**

Repetir el proceso con:
- Email: jmolano@chispitas.local
- Usuario: jmolano
- Contraseña: [contraseña de FreeIPA]

**Libreta de Direcciones LDAP:**

1. En Thunderbird: Herramientas → Libreta de direcciones
2. Archivo → Nuevo → Directorio LDAP
3. Configuración:
   - Nombre: Directorio Chispitas
   - Hostname: ipa.chispitas.local
   - Base DN: cn=users,cn=accounts,dc=chispitas,dc=local
   - Puerto: 389
   - Bind DN: uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local

## Plan de Auditoría y Validación

### Prueba 1: Resolución DNS

```bash
# Verificar que DNS resuelve correctamente
dig chispitas.local
dig odoo.chispitas.local
dig crm.chispitas.local
dig mail.chispitas.local
dig files.chispitas.local

# Verificar registro MX
dig -t MX chispitas.local

# Salida esperada:
# chispitas.local.    IN  MX  10 mail.chispitas.local.
```

### Prueba 2: Acceso a Servicios Web via Proxy

```bash
# Probar conectividad HTTP
curl -I http://odoo.chispitas.local
curl -I http://crm.chispitas.local
curl -I http://hrm.chispitas.local
curl -I http://erp.chispitas.local

# Abrir en navegador
firefox http://odoo.chispitas.local &
firefox http://crm.chispitas.local &
firefox http://hrm.chispitas.local &
firefox http://erp.chispitas.local &
```

**Resultados esperados:**
- Odoo: Página de login de Odoo
- CRM: Página de login de SuiteCRM
- HRM: Página de login de OrangeHRM
- ERP: Página de login de Dolibarr

### Prueba 3: Servidor de Correo

**Paso 1 - Enviar correo:**

1. En Thunderbird, con cuenta de jmolano
2. Redactar → Nuevo mensaje
3. Para: lhernandez@chispitas.local
4. Asunto: Prueba de correo - Área Comercial a Producción
5. Mensaje: "Hola Luis, prueba de integración del servidor de correo."
6. Enviar

**Paso 2 - Recibir correo:**

1. Cambiar a cuenta de lhernandez en Thunderbird
2. Verificar bandeja de entrada
3. El mensaje debe aparecer

**Paso 3 - Responder:**

1. Responder al mensaje
2. Verificar que jmolano lo recibe

### Prueba 4: Servidor de Archivos (Matriz de Permisos)

**Usuario: lhernandez (Grupo: GRP_Produccion)**

```bash
# Listar shares disponibles
smbclient -L //files.chispitas.local -U lhernandez
# Ingresar contraseña cuando se solicite

# Conectar a share de Producción (DEBE FUNCIONAR)
smbclient //files.chispitas.local/Produccion -U lhernandez
> ls
> mkdir test_lhernandez_produccion
> put /etc/hosts hosts_backup.txt
> ls
> rm hosts_backup.txt
> exit

# Intentar conectar a share Comercial (DEBE FALLAR - sin permisos)
smbclient //files.chispitas.local/Comercial -U lhernandez
> mkdir test_comercial
# Salida esperada: NT_STATUS_ACCESS_DENIED

# Conectar a share Compartido (DEBE FUNCIONAR - solo lectura)
smbclient //files.chispitas.local/Compartido -U lhernandez
> ls
> mkdir test_write
# Salida esperada: NT_STATUS_ACCESS_DENIED (no tiene permisos de escritura)
```

**Usuario: jmolano (Grupo: GRP_Comercial)**

```bash
# Conectar a share Comercial (DEBE FUNCIONAR)
smbclient //files.chispitas.local/Comercial -U jmolano
> mkdir test_jmolano_comercial
> ls
> exit

# Intentar conectar a Producción (DEBE FALLAR)
smbclient //files.chispitas.local/Produccion -U jmolano
> mkdir test_produccion
# Salida esperada: NT_STATUS_ACCESS_DENIED
```

**Matriz de Permisos Esperada:**

| Usuario | Grupo | Produccion | Comercial | RRHH | Gerencia | Compartido |
|---------|-------|------------|-----------|------|----------|------------|
| lhernandez | GRP_Produccion | RW | ✗ | ✗ | ✗ | R |
| jmolano | GRP_Comercial | ✗ | RW | ✗ | ✗ | R |
| egonzales | GRP_RRHH | ✗ | ✗ | RW | ✗ | R |
| klinares | GRP_Admins_Dominio | RW | RW | RW | RW | RW |

*RW = Lectura/Escritura, R = Solo lectura, ✗ = Sin acceso*

### Prueba 5: Autenticación Unificada (SSO/LDAP)

**Objetivo:** Verificar que los usuarios pueden autenticarse en aplicaciones web usando sus credenciales de FreeIPA.

**Nota:** Esta prueba requiere configuración adicional de LDAP en cada aplicación.

```bash
# Acceder a SuiteCRM
firefox http://crm.chispitas.local &

# Intentar login con:
# Usuario: jmolano
# Contraseña: [contraseña de FreeIPA]

# Si la integración LDAP está configurada, debe permitir el acceso
```

### Prueba 6: LDAP Direct Query

```bash
# Verificar usuarios en FreeIPA
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <FREEIPA_ADMIN_PASSWORD> \
  -b "cn=users,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixAccount)" uid cn mail

# Verificar grupos
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <FREEIPA_ADMIN_PASSWORD> \
  -b "cn=groups,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixGroup)" cn member
```

## Comandos Útiles

### Traefik

```bash
# Ver logs
docker logs -f traefik

# Reiniciar
docker-compose restart traefik

# Ver configuración actual
docker exec traefik cat /etc/traefik/traefik.yml

# Ver rutas dinámicas
docker exec traefik cat /etc/traefik/dynamic/services.yml
```

### Diagnóstico de Red

```bash
# Verificar conectividad
ping odoo.chispitas.local
ping mail.chispitas.local
ping files.chispitas.local

# Verificar puertos
nc -zv 192.168.1.10 8069  # Odoo
nc -zv 192.168.1.20 25    # SMTP
nc -zv 192.168.1.20 445   # Samba

# Trace route
traceroute odoo.chispitas.local

# Ver rutas
ip route show
```

### Limpieza

```bash
# Limpiar cache DNS
sudo systemd-resolve --flush-caches

# Reiniciar networking
sudo systemctl restart NetworkManager
```

## Troubleshooting

### No resuelve nombres DNS

```bash
# Verificar resolv.conf
cat /etc/resolv.conf

# Debe contener:
# nameserver 192.168.1.10

# Verificar que FreeIPA está accesible
ping 192.168.1.10
dig @192.168.1.10 chispitas.local

# Reconfigurar DNS
sudo nano /etc/systemd/resolved.conf
# [Resolve]
# DNS=192.168.1.10
sudo systemctl restart systemd-resolved
```

### Traefik no enruta correctamente

```bash
# Verificar logs
docker logs traefik | grep -i error

# Verificar configuración
docker exec traefik cat /etc/traefik/dynamic/services.yml

# Verificar que los backends estén accesibles
curl -I http://192.168.1.10:8069
curl -I http://192.168.1.10:8081

# Reiniciar Traefik
docker-compose restart traefik
```

### No puede conectar a Samba

```bash
# Instalar cliente si falta
sudo apt-get install smbclient

# Verificar conectividad
ping 192.168.1.20
nc -zv 192.168.1.20 445

# Listar shares
smbclient -L //192.168.1.20 -U lhernandez

# Verificar usuario existe en Samba (desde Host-SVR-02)
docker exec samba-server pdbedit -L | grep lhernandez
```

## Recursos

- Traefik Documentation: https://doc.traefik.io/traefik/
- Thunderbird LDAP: https://support.mozilla.org/en-US/kb/ldap-address-books
- Samba Client: https://www.samba.org/samba/docs/current/man-html/smbclient.1.html
