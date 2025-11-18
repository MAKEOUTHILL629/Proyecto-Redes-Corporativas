# Host-SVR-01: Servidor Principal de Aplicaciones

## Especificaciones del Host

- **Sistema Operativo:** Windows 11 con WSL2
- **Hardware:** AMD Ryzen 5 7600x, 32GB RAM
- **Docker:** Docker Desktop con backend WSL2
- **Hostname:** svr-powerhouse.chispitas.local
- **IP LAN:** 192.168.1.10

## Servicios Desplegados

Este host ejecuta los servicios principales de aplicaciones empresariales y el servidor de directorio:

### 1. FreeIPA Server (Principal)
- **IP:** 172.20.1.10
- **Hostname:** ipa.chispitas.local
- **Puertos:** 80, 443, 389, 636, 88, 464, 53
- **Función:** Servidor LDAP, DNS, Kerberos y CA
- **Acceso Web:** https://192.168.1.10 o https://ipa.chispitas.local

### 2. Odoo Manufacturing
- **IP:** 172.20.1.21
- **Puerto:** 8069
- **Base de Datos:** PostgreSQL (172.20.1.20)
- **Función:** ERP para área de Producción
- **Acceso:** http://192.168.1.10:8069 o http://odoo.chispitas.local

### 3. SuiteCRM
- **IP:** 172.20.1.31
- **Puerto:** 8081
- **Base de Datos:** MariaDB (172.20.1.30)
- **Función:** CRM para área Comercial
- **Acceso:** http://192.168.1.10:8081 o http://crm.chispitas.local

### 4. OrangeHRM
- **IP:** 172.20.1.41
- **Puerto:** 8082
- **Base de Datos:** MariaDB (172.20.1.40)
- **Función:** Sistema de Recursos Humanos
- **Acceso:** http://192.168.1.10:8082 o http://hrm.chispitas.local

### 5. Dolibarr
- **IP:** 172.20.1.51
- **Puerto:** 8083
- **Base de Datos:** MariaDB (172.20.1.50)
- **Función:** ERP para área Administrativa/Financiera
- **Acceso:** http://192.168.1.10:8083 o http://erp.chispitas.local

## Instrucciones de Despliegue

### Prerrequisitos

1. **Docker Desktop instalado y configurado:**
   ```powershell
   # Verificar Docker
   docker --version
   docker-compose --version
   ```

2. **WSL2 configurado:**
   ```powershell
   wsl --list --verbose
   # Asegurarse de que Docker Desktop usa WSL2
   ```

3. **Red Docker creada:**
   ```powershell
   docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
   ```

4. **Archivo .env configurado:**
   ```powershell
   # Copiar el template desde la raíz del proyecto
   Copy-Item ..\.env.template .env
   # Editar .env con las contraseñas deseadas
   notepad .env
   ```

### Despliegue

1. **Abrir PowerShell o Terminal Windows:**
   ```powershell
   cd C:\ruta\al\proyecto\host-1-powerhouse
   ```

2. **Iniciar los servicios:**
   ```powershell
   docker-compose up -d
   ```

3. **Verificar el estado:**
   ```powershell
   docker-compose ps
   docker-compose logs -f
   ```

4. **Esperar a que FreeIPA se inicialice (primera vez toma ~5-10 minutos):**
   ```powershell
   docker logs -f freeipa-server
   # Esperar mensaje: "FreeIPA server configured."
   ```

### Post-Instalación

#### 1. Configurar FreeIPA

**Acceder al contenedor:**
```powershell
docker exec -it freeipa-server /bin/bash
```

**Autenticarse como admin:**
```bash
kinit admin
# Ingresar la contraseña: valor de FREEIPA_ADMIN_PASSWORD del .env
```

**Ejecutar script de poblamiento:**
```bash
chmod +x /setup_chispitas.sh
/setup_chispitas.sh
```

**Verificar usuarios creados:**
```bash
ipa user-find
```

**Verificar grupos:**
```bash
ipa group-find
```

#### 2. Configurar DNS en FreeIPA

**Via CLI (dentro del contenedor):**
```bash
# Registros A para servicios web (apuntan al proxy)
ipa dnsrecord-add chispitas.local odoo --a-rec=192.168.1.30
ipa dnsrecord-add chispitas.local crm --a-rec=192.168.1.30
ipa dnsrecord-add chispitas.local hrm --a-rec=192.168.1.30
ipa dnsrecord-add chispitas.local erp --a-rec=192.168.1.30

# Registros para infraestructura
ipa dnsrecord-add chispitas.local mail --a-rec=192.168.1.20
ipa dnsrecord-add chispitas.local files --a-rec=192.168.1.20

# Registro MX
ipa dnsrecord-add chispitas.local @ --mx-rec="10 mail.chispitas.local."
```

**Via Web UI:**
1. Acceder a https://192.168.1.10
2. Login: admin / contraseña del .env
3. Network Services → DNS → DNS Zones
4. Seleccionar zona `chispitas.local`
5. Agregar registros según la tabla anterior

#### 3. Configurar Cliente DNS (Windows)

**En WSL2:**
```bash
sudo nano /etc/resolv.conf
# Agregar al inicio:
nameserver 172.20.1.10
nameserver 192.168.1.10
```

**En Windows (opcional):**
- Panel de Control → Redes → Propiedades del adaptador
- Propiedades IPv4 → DNS preferido: 192.168.1.10

#### 4. Probar Servicios

**FreeIPA Web UI:**
```
https://192.168.1.10
Usuario: admin
Contraseña: [FREEIPA_ADMIN_PASSWORD]
```

**Odoo:**
```
http://192.168.1.10:8069
Usuario: admin
Contraseña: admin (primera vez, se solicita cambio)
Base de datos: odoo_db
```

**SuiteCRM:**
```
http://192.168.1.10:8081
Usuario: [SUITECRM_ADMIN_USER]
Contraseña: [SUITECRM_ADMIN_PASSWORD]
```

**OrangeHRM:**
```
http://192.168.1.10:8082
Completar wizard de instalación
```

**Dolibarr:**
```
http://192.168.1.10:8083
Completar wizard de instalación
```

## Comandos Útiles

### Ver logs de un servicio específico:
```powershell
docker-compose logs -f freeipa-server
docker-compose logs -f odoo
docker-compose logs -f suitecrm
```

### Reiniciar un servicio:
```powershell
docker-compose restart freeipa-server
docker-compose restart odoo
```

### Detener todos los servicios:
```powershell
docker-compose down
```

### Detener y eliminar volúmenes (CUIDADO - elimina datos):
```powershell
docker-compose down -v
```

### Backup de volúmenes:
```powershell
# Ejemplo para FreeIPA
docker run --rm -v host-1-powerhouse_freeipa_data:/data -v ${PWD}/backups:/backup alpine tar czf /backup/freeipa-backup-$(date +%Y%m%d).tar.gz /data
```

### Entrar a un contenedor:
```powershell
docker exec -it freeipa-server /bin/bash
docker exec -it odoo-manufacturing /bin/bash
docker exec -it postgres-odoo /bin/bash
```

## Troubleshooting

### FreeIPA no inicia
- Verificar que los puertos no estén en uso: `netstat -ano | findstr :80`
- Revisar logs: `docker logs freeipa-server`
- Asegurar suficiente RAM disponible (FreeIPA requiere ~2GB)

### Odoo no se conecta a PostgreSQL
- Verificar que postgres-odoo esté healthy: `docker ps`
- Revisar contraseña en .env
- Logs: `docker logs postgres-odoo`

### No resuelve DNS
- Verificar que FreeIPA esté corriendo: `docker ps | grep freeipa`
- Probar resolución: `nslookup chispitas.local 192.168.1.10`
- Verificar /etc/resolv.conf en WSL2

### Aplicaciones web no accesibles
- Verificar firewall de Windows
- Probar con `curl http://localhost:8069` desde WSL2
- Verificar que el contenedor esté en la red correcta: `docker network inspect chispitas_net`

## Recursos

- FreeIPA Documentation: https://www.freeipa.org/page/Documentation
- Odoo Documentation: https://www.odoo.com/documentation
- SuiteCRM Documentation: https://docs.suitecrm.com/
- OrangeHRM Documentation: https://orangehrm.com/documentation/
- Dolibarr Documentation: https://wiki.dolibarr.org/
