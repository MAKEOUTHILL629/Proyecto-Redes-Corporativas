# Guía de Inicio Rápido
## Proyecto Chispitas - Despliegue Rápido

Esta guía proporciona los pasos mínimos para tener el sistema funcionando rápidamente.

---

## Requisitos Mínimos

- 3 máquinas (físicas o virtuales) en la misma red LAN
- Docker y Docker Compose instalados en las 3 máquinas
- Mínimo 40GB de espacio en disco total
- Conectividad de red entre hosts
- 10-15 minutos para el despliegue inicial

---

## Paso 1: Configuración Inicial (5 minutos)

### En todas las máquinas:

```bash
# Clonar repositorio
git clone <url-repo>
cd Proyecto-Redes-Corporativas

# IMPORTANTE: Copiar y editar archivo de entorno EN EL DIRECTORIO RAÍZ
cp .env.template .env
nano .env  # Ajustar IPs y contraseñas

# Crear red Docker
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

**Variables críticas en .env:**
- `HOST_SVR_01_IP` (ej: 192.168.1.10)
- `HOST_SVR_02_IP` (ej: 192.168.1.20)
- `HOST_SVR_03_IP` (ej: 192.168.1.30)
- `FREEIPA_ADMIN_PASSWORD` (cambiar!)
- `MARIADB_ROOT_PASSWORD` (cambiar!)
- `POSTGRES_ODOO_PASSWORD` (cambiar!)
- Todas las contraseñas de bases de datos y aplicaciones

**⚠️ IMPORTANTE**: El archivo `.env` debe estar en el directorio raíz del proyecto (`Proyecto-Redes-Corporativas/.env`), NO dentro de los subdirectorios `host-X-xxx/`.

---

## Paso 2: Desplegar Host-SVR-01 (5-10 minutos)

**En la máquina con más recursos (Windows/Ryzen 5):**

```bash
cd host-1-powerhouse
docker-compose up -d

# Esperar a que FreeIPA se inicialice (~5-10 min primera vez)
docker logs -f freeipa-server
# Esperar: "FreeIPA server configured."
# Presionar Ctrl+C

# Poblar FreeIPA
docker exec -it freeipa-server bash
kinit admin  # Password del .env
chmod +x /setup_chispitas.sh
/setup_chispitas.sh
exit
```

---

## Paso 3: Configurar DNS (2 minutos)

**En todas las máquinas, apuntar DNS a FreeIPA:**

```bash
# Linux/Mac
sudo nano /etc/resolv.conf
# Agregar al inicio:
nameserver 192.168.1.10  # IP de Host-SVR-01

# Windows (WSL2)
# Mismos pasos que Linux
```

**Probar:**
```bash
dig chispitas.local
dig odoo.chispitas.local
```

---

## Paso 4: Desplegar Host-SVR-02 (3 minutos)

**En MacOS:**

```bash
cd host-2-infra
docker-compose up -d

# Configurar Samba
docker exec -it samba-server bash
smbpasswd -w <FREEIPA_ADMIN_PASSWORD>
smbpasswd -a lhernandez  # Password: User2Pass2024!
smbpasswd -a jmolano     # Password: User3Pass2024!
exit
```

---

## Paso 5: Desplegar Host-SVR-03 (2 minutos)

**En Lubuntu:**

```bash
cd host-3-edge
docker-compose up -d

# Ver dashboard
firefox http://localhost:8080 &
```

---

## Paso 6: Verificación (2 minutos)

```bash
# Probar DNS
dig odoo.chispitas.local

# Probar servicios web
curl -I http://odoo.chispitas.local
curl -I http://crm.chispitas.local

# Probar Samba
smbclient -L //files.chispitas.local -U lhernandez

# Abrir en navegador
firefox http://odoo.chispitas.local &
firefox http://crm.chispitas.local &
```

---

## Usuarios de Prueba

| Usuario | Password | Grupo | Email |
|---------|----------|-------|-------|
| klinares | User1Pass2024! | Administrador | klinares@chispitas.local |
| lhernandez | User2Pass2024! | Producción | lhernandez@chispitas.local |
| jmolano | User3Pass2024! | Comercial | jmolano@chispitas.local |
| egonzales | User4Pass2024! | RRHH | egonzales@chispitas.local |

---

## Acceso a Servicios

### Aplicaciones Web

- **Odoo:** http://odoo.chispitas.local
- **SuiteCRM:** http://crm.chispitas.local
- **OrangeHRM:** http://hrm.chispitas.local
- **Dolibarr:** http://erp.chispitas.local
- **FreeIPA:** https://192.168.1.10
- **Traefik Dashboard:** http://192.168.1.30:8080

### Servicios de Red

- **Correo (SMTP):** mail.chispitas.local:587
- **Correo (IMAP):** mail.chispitas.local:143
- **Archivos (SMB):** \\\\files.chispitas.local
- **DNS:** 192.168.1.10
- **LDAP:** ldap://ipa.chispitas.local:389

---

## Próximos Pasos

1. **Configurar clientes de correo** (Thunderbird) - Ver docs/TESTING_GUIDE.md
2. **Probar permisos de archivos** - Ver docs/TESTING_GUIDE.md
3. **Configurar LDAP en aplicaciones** - Ver README de cada host
4. **Realizar pruebas completas** - Ver docs/TESTING_GUIDE.md

---

## Problemas Comunes

### DNS no resuelve
```bash
# Verificar que FreeIPA está corriendo
docker ps | grep freeipa
# Verificar /etc/resolv.conf
cat /etc/resolv.conf
```

### Servicios web no accesibles
```bash
# Verificar Traefik
docker logs traefik
# Verificar conectividad
ping 192.168.1.10
curl -I http://192.168.1.10:8069
```

### Samba no autentica
```bash
# Agregar usuario
docker exec -it samba-server smbpasswd -a <username>
# Verificar usuarios
docker exec samba-server pdbedit -L
```

---

## Documentación Completa

- **Guía de Despliegue Completa:** docs/DEPLOYMENT_GUIDE.md
- **Configuración de Red:** docs/NETWORK_CONFIGURATION.md
- **Guía de Pruebas:** docs/TESTING_GUIDE.md
- **Host-SVR-01:** host-1-powerhouse/README.md
- **Host-SVR-02:** host-2-infra/README.md
- **Host-SVR-03:** host-3-edge/README.md

---

## Soporte

Para problemas o dudas, consulte la documentación específica de cada componente o revise los logs:

```bash
# Ver logs de un servicio
docker logs <nombre-contenedor>

# Ver todos los logs
docker-compose logs -f
```

**Autores:** Grupo 3-302 - Redes Corporativas
