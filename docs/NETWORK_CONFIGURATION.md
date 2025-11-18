# Configuración de Red - Proyecto Chispitas

## 1. Arquitectura de Red

La infraestructura utiliza una red LAN física común (`192.168.1.0/24`) con redes Docker bridge personalizadas en cada host para permitir la comunicación entre contenedores.

### Plan de Direccionamiento IP

#### Hosts Físicos (Red LAN)
| Host | Hostname | IP Estática Recomendada | Sistema Operativo |
|------|----------|------------------------|-------------------|
| Host-SVR-01 | SVR-POWERHOUSE | 192.168.1.10 | Windows 11 (WSL2) |
| Host-SVR-02 | SVR-INFRA | 192.168.1.20 | MacOS (M4) |
| Host-SVR-03 | SVR-EDGE | 192.168.1.30 | Lubuntu |

#### Contenedores - Red Docker (Subred: 172.20.0.0/16)

**Host-SVR-01 (Windows):**
| Servicio | IP Estática | Puerto(s) | Descripción |
|----------|-------------|-----------|-------------|
| FreeIPA Server | 172.20.1.10 | 80, 443, 389, 636, 88, 464, 53 | Servidor LDAP/DNS/Kerberos/CA |
| PostgreSQL (Odoo) | 172.20.1.20 | 5432 | Base de datos Odoo |
| Odoo | 172.20.1.21 | 8069 | ERP Manufactura |
| MariaDB (CRM) | 172.20.1.30 | 3306 | Base de datos SuiteCRM |
| SuiteCRM | 172.20.1.31 | 80 | CRM Comercial |
| MariaDB (HRM) | 172.20.1.40 | 3306 | Base de datos OrangeHRM |
| OrangeHRM | 172.20.1.41 | 80 | HRM Recursos Humanos |
| MariaDB (ERP) | 172.20.1.50 | 3306 | Base de datos Dolibarr |
| Dolibarr | 172.20.1.51 | 80 | ERP Administrativo |

**Host-SVR-02 (MacOS):**
| Servicio | IP Estática | Puerto(s) | Descripción |
|----------|-------------|-----------|-------------|
| Postfix/Dovecot | 172.20.2.10 | 25, 587, 143, 993, 110, 995 | Servidor de Correo |
| Samba | 172.20.2.20 | 139, 445 | Servidor de Archivos |

**Host-SVR-03 (Lubuntu):**
| Servicio | IP Estática | Puerto(s) | Descripción |
|----------|-------------|-----------|-------------|
| Traefik | 172.20.3.10 | 80, 443, 8080 | Proxy Inverso |

## 2. Configuración de Redes Docker

### Crear Red Bridge Personalizada

Ejecute estos comandos en **cada host** para crear la red Docker personalizada:

```bash
# En Host-SVR-01 (Windows - PowerShell o CMD)
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net

# En Host-SVR-02 (MacOS - Terminal)
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net

# En Host-SVR-03 (Lubuntu - Terminal)
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

### Verificar Creación de Red

```bash
docker network ls
docker network inspect chispitas_net
```

## 3. Configuración de DNS

### Configuración en Hosts

Para que los hosts puedan resolver los nombres del dominio `chispitas.local`, deben apuntar al servidor DNS de FreeIPA.

#### En Host-SVR-01 (Windows con WSL2):

1. **En WSL2:**
   ```bash
   sudo nano /etc/resolv.conf
   ```
   Agregar:
   ```
   nameserver 172.20.1.10
   nameserver 192.168.1.10
   ```

2. **En Windows (opcional, para resolver desde el host):**
   - Panel de Control → Redes → Propiedades del adaptador
   - IPv4 → Propiedades → DNS preferido: `192.168.1.10`

#### En Host-SVR-02 (MacOS):

```bash
# Crear archivo de configuración DNS
sudo mkdir -p /etc/resolver
sudo bash -c 'echo "nameserver 192.168.1.10" > /etc/resolver/chispitas.local'
```

#### En Host-SVR-03 (Lubuntu):

```bash
sudo nano /etc/resolv.conf
```
Agregar al inicio:
```
nameserver 192.168.1.10
nameserver 8.8.8.8
```

**Nota:** Para hacer permanente en Lubuntu (systemd-resolved):
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

## 4. Registros DNS en FreeIPA

Una vez que FreeIPA esté en funcionamiento, configure estos registros DNS:

### Registros A (Apuntan al Proxy en Host-SVR-03)
```bash
# Servicios web (todos pasan por el proxy inverso)
odoo.chispitas.local.     A    192.168.1.30
crm.chispitas.local.      A    192.168.1.30
hrm.chispitas.local.      A    192.168.1.30
erp.chispitas.local.      A    192.168.1.30
```

### Registros A (Servicios directos)
```bash
# Servicios de infraestructura (acceso directo)
mail.chispitas.local.     A    192.168.1.20
files.chispitas.local.    A    192.168.1.20
ipa.chispitas.local.      A    192.168.1.10
```

### Registro MX (Correo)
```bash
chispitas.local.    MX    10 mail.chispitas.local.
```

## 5. Configuración de Firewall (Opcional)

Si tiene firewalls activos en los hosts, asegúrese de permitir estos puertos:

### Host-SVR-01 (FreeIPA y Aplicaciones)
- TCP: 80, 443, 389, 636, 88, 464, 53, 8069
- UDP: 53, 88, 464

### Host-SVR-02 (Correo y Archivos)
- TCP: 25, 587, 143, 993, 110, 995, 139, 445
- UDP: 137, 138

### Host-SVR-03 (Proxy)
- TCP: 80, 443, 8080

## 6. Pruebas de Conectividad

### Verificar Conectividad entre Hosts

Desde cada host, ejecute:

```bash
# Desde Host-SVR-01
ping 192.168.1.20  # Host-SVR-02
ping 192.168.1.30  # Host-SVR-03

# Desde Host-SVR-02
ping 192.168.1.10  # Host-SVR-01
ping 192.168.1.30  # Host-SVR-03

# Desde Host-SVR-03
ping 192.168.1.10  # Host-SVR-01
ping 192.168.1.20  # Host-SVR-02
```

### Verificar Resolución DNS

Después de configurar FreeIPA (ejecutar desde Host-SVR-03):

```bash
dig @192.168.1.10 chispitas.local
dig @192.168.1.10 odoo.chispitas.local
dig @192.168.1.10 -t MX chispitas.local
```

## 7. Consideraciones Importantes

1. **Sincronización de Tiempo:** Asegúrese de que todos los hosts tengan la hora sincronizada (Kerberos lo requiere).
   ```bash
   # En Linux/Mac
   sudo ntpdate pool.ntp.org
   
   # O usar systemd-timesyncd
   timedatectl set-ntp true
   ```

2. **Hostnames:** Configure el hostname de cada máquina para que coincida:
   ```bash
   # En Host-SVR-01 (WSL2)
   sudo hostnamectl set-hostname svr-powerhouse.chispitas.local
   
   # En Host-SVR-02 (MacOS)
   sudo scutil --set HostName svr-infra.chispitas.local
   
   # En Host-SVR-03 (Lubuntu)
   sudo hostnamectl set-hostname svr-edge.chispitas.local
   ```

3. **Archivo /etc/hosts:** Agregue entradas temporales mientras se configura FreeIPA:
   ```bash
   192.168.1.10    svr-powerhouse.chispitas.local svr-powerhouse ipa.chispitas.local
   192.168.1.20    svr-infra.chispitas.local svr-infra mail.chispitas.local files.chispitas.local
   192.168.1.30    svr-edge.chispitas.local svr-edge
   ```

## 8. Topología de Red

```
                             Internet
                                |
                          [Router LAN]
                                |
                    192.168.1.0/24 (Red LAN)
                                |
        +-----------------------+-----------------------+
        |                       |                       |
   Host-SVR-01            Host-SVR-02              Host-SVR-03
  192.168.1.10           192.168.1.20             192.168.1.30
        |                       |                       |
  chispitas_net          chispitas_net           chispitas_net
   172.20.0.0/16         172.20.0.0/16           172.20.0.0/16
        |                       |                       |
   [Contenedores]         [Contenedores]          [Contenedores]
   - FreeIPA              - Mail Server           - Traefik (Proxy)
   - Odoo                 - Samba                 - Cliente Pruebas
   - SuiteCRM
   - OrangeHRM
   - Dolibarr
```

## 9. Troubleshooting

### Problema: Los contenedores no se comunican entre hosts

**Solución:** Use las IPs de la LAN (192.168.1.x) para comunicación entre hosts, no las IPs internas de Docker (172.20.x.x).

### Problema: DNS no resuelve

**Solución:** 
1. Verificar que FreeIPA esté corriendo: `docker ps | grep freeipa`
2. Verificar puerto 53: `sudo netstat -tuln | grep :53`
3. Probar resolución directa: `dig @192.168.1.10 chispitas.local`

### Problema: Diferencia de hora (Kerberos)

**Solución:** Sincronizar relojes de todos los hosts:
```bash
sudo ntpdate -u pool.ntp.org
```
