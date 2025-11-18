# Instrucciones de Configuración Rápida - Host-SVR-01

## ⚠️ IMPORTANTE: Pre-requisitos

Antes de continuar, asegúrese de:

1. Tener Docker Desktop instalado y corriendo
2. Tener permisos de administrador/root
3. Tener al menos 20GB de espacio en disco libre

## Configuración Automática de .env

El archivo `.env` **YA ESTÁ INCLUIDO** en este directorio con valores predeterminados seguros para desarrollo/pruebas.

**IMPORTANTE**: 
- Para seguridad, cambie las contraseñas antes de usar en producción
- El archivo .env se carga automáticamente por Docker Compose
- No necesita crearlo manualmente

### Editar contraseñas (RECOMENDADO para producción)

```bash
# Editar el archivo .env en este directorio
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
notepad .env
```

**Variables críticas a cambiar:**
- `FREEIPA_ADMIN_PASSWORD` - Contraseña del administrador de FreeIPA
- `FREEIPA_DM_PASSWORD` - Contraseña del Directory Manager
- `POSTGRES_ODOO_PASSWORD` - Contraseña de PostgreSQL
- `MARIADB_ROOT_PASSWORD` - Contraseña root de MariaDB
- `MARIADB_CRM_PASSWORD` - Contraseña para el CRM
- `MARIADB_HRM_PASSWORD` - Contraseña para OrangeHRM
- `MARIADB_ERP_PASSWORD` - Contraseña para Dolibarr
- `DOLIBARR_ADMIN_PASSWORD` - Contraseña admin de Dolibarr

## Paso 1: Crear la red Docker

```bash
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

## Paso 2: Configurar SuiteCRM (OPCIONAL)

**NOTA IMPORTANTE**: SuiteCRM no tiene imagen Docker oficial. El servicio está comentado en docker-compose.yml.

**Opciones:**

1. **Omitir CRM por ahora** (recomendado para primera prueba)
   - No hacer nada, el servicio está comentado
   - Los demás servicios funcionarán normalmente

2. **Usar EspoCRM como alternativa** (más fácil)
   - Ver `SUITECRM_SETUP.md` para instrucciones detalladas
   - Descomentar la sección de EspoCRM en docker-compose.yml

3. **Instalar SuiteCRM manualmente**
   - Ver `SUITECRM_SETUP.md` para crear imagen personalizada

## Paso 3: Iniciar los servicios

```bash
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
docker-compose up -d
```

**NOTA**: Docker Compose cargará automáticamente el archivo `.env` de este directorio. No debería ver advertencias sobre variables no configuradas.

### Verificar el despliegue

```bash
# Ver todos los contenedores
docker ps

# Ver logs de un servicio específico
docker logs -f freeipa-server
docker logs -f odoo-manufacturing
docker logs -f orangehrm
docker logs -f dolibarr-erp
```

## Paso 4: Esperar inicialización de FreeIPA

FreeIPA tarda **5-10 minutos** en inicializarse por primera vez:

```bash
docker logs -f freeipa-server
# Esperar mensaje: "The ipa-server-install command was successful"
# Presionar Ctrl+C para salir
```

### ⚠️ Si FreeIPA se reinicia constantemente

Si ve `Restarting (255)` en el estado de freeipa-server:

```bash
# Ver el estado y logs
docker ps | findstr freeipa
docker logs freeipa-server
```

**Errores comunes**:

1. **"Failed to mount cgroup at /sys/fs/cgroup/systemd: Operation not permitted"**
   - **Solución**: La configuración ya está corregida con `:rw` y `SYS_ADMIN` capability
   - Limpie los volúmenes y reinicie:
   ```bash
   docker-compose down
   docker volume rm host-1-powerhouse_freeipa_data host-1-powerhouse_freeipa_logs
   docker-compose up -d
   ```

2. **Inicialización en curso**
   - **Solución**: Sea paciente - La primera instalación toma 10 minutos
   - Monitoree con: `docker logs -f freeipa-server`

3. **Volúmenes corruptos**
   - **Solución**: Limpie y reinicie:
   ```bash
   docker-compose down
   docker volume rm host-1-powerhouse_freeipa_data host-1-powerhouse_freeipa_logs
   docker-compose up -d
   ```

4. **Guía completa**: Ver `FREEIPA_TROUBLESHOOTING.md` para diagnóstico detallado

## Servicios Disponibles

Después del despliegue exitoso:

| Servicio | URL | Puerto | Estado |
|----------|-----|--------|--------|
| FreeIPA | https://192.168.1.10 | 443 | ✅ Activo |
| Odoo | http://192.168.1.10:8069 | 8069 | ✅ Activo |
| OrangeHRM | http://192.168.1.10:8082 | 8082 | ✅ Activo |
| Dolibarr | http://192.168.1.10:8083 | 8083 | ✅ Activo |
| SuiteCRM/CRM | http://192.168.1.10:8081 | 8081 | ⚠️ Comentado (ver SUITECRM_SETUP.md) |

## Solución de Problemas

### Error: "variable is not set"

**Causa**: El archivo `.env` no existe en el directorio `host-1-powerhouse`.

**Solución**: 
```bash
# Verificar que existe .env en el directorio host-1-powerhouse
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
dir .env

# Si no existe, copiarlo desde el directorio raíz
copy ..\. env .env
```

Docker Compose busca el archivo `.env` en el **directorio actual** (donde está docker-compose.yml), no en el directorio padre.

### Error: "network chispitas_net not found"

**Solución**: 
```bash
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

### Error: "pull access denied for salesagility/suitecrm"

**Causa**: La imagen de SuiteCRM no existe en Docker Hub.

**Solución**: El servicio de SuiteCRM ahora está comentado por defecto. Ver `SUITECRM_SETUP.md` para alternativas.

### Error: "Container postgres-odoo is unhealthy" or "dependency failed to start"

**Causa**: PostgreSQL no pudo iniciar correctamente, generalmente porque:
1. El archivo `.env` no se cargó (variables de contraseña vacías)
2. Volúmenes de datos corruptos de intentos anteriores

**Solución 1 - Verificar .env**:
```bash
# Asegurarse de que .env existe en host-1-powerhouse
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
dir .env
type .env | findstr POSTGRES_ODOO_PASSWORD
```

**Solución 2 - Limpiar y reiniciar**:
```bash
# Detener todos los contenedores
docker-compose down

# Eliminar volúmenes (CUIDADO: esto borra datos)
docker volume rm host-1-powerhouse_postgres_odoo_data

# Reiniciar
docker-compose up -d

# Ver logs de postgres
docker logs -f postgres-odoo
```

**Solución 3 - Verificar contraseña no vacía**:
```bash
# El problema común es que POSTGRES_PASSWORD está vacío
# Editar .env y asegurar que tiene un valor:
notepad .env
# Buscar: POSTGRES_ODOO_PASSWORD=OdooSecurePass2024!
# Debe tener un valor, no estar vacío
```

**Causa**: PowerShell está en el directorio equivocado.

**Solución**:
```powershell
# Verificar directorio actual
pwd

# Debe mostrar: C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
# Si no, navegar al correcto:
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
```

## Verificación Final

Para verificar que todo funciona:

```bash
# 1. Ver todos los contenedores corriendo
docker ps

# Debe mostrar aproximadamente 8 contenedores:
# - freeipa-server
# - postgres-odoo
# - odoo-manufacturing
# - mariadb-crm
# - mariadb-hrm
# - orangehrm
# - mariadb-erp
# - dolibarr-erp

# 2. Probar acceso web
# Abrir en navegador:
# - http://localhost:8069 (Odoo)
# - http://localhost:8082 (OrangeHRM)
# - http://localhost:8083 (Dolibarr)
# - https://localhost (FreeIPA)

# 3. Ver logs si hay problemas
docker-compose logs
```

## Próximos Pasos

1. **Configurar FreeIPA**: Ver `README.md` sección "Post-Instalación"
2. **Configurar SuiteCRM** (opcional): Ver `SUITECRM_SETUP.md`
3. **Continuar con Host-SVR-02**: Servidor de correo y archivos
4. **Continuar con Host-SVR-03**: Proxy inverso

## Documentación de Resolución de Problemas

Si encuentra problemas específicos, consulte estas guías:

- **FREEIPA_TROUBLESHOOTING.md** - Problemas de FreeIPA (reinicio continuo, etc.)
- **SUITECRM_SETUP.md** - Alternativas de CRM y configuración
- **ENV_FILES_README.md** - Información sobre archivos .env
- **README.md** - Documentación completa del host

## Notas Adicionales

- **Primera vez**: Los contenedores tardan más tiempo en iniciar mientras descargan las imágenes
- **FreeIPA**: Es el servicio más importante y el que más tarda en inicializar (5-10 minutos)
- **Recursos**: Asegúrese de tener al menos 8GB RAM disponibles para Docker Desktop
- **Firewall**: Windows puede solicitar permisos para Docker - permitir acceso
- **Reinicio de FreeIPA**: Si FreeIPA se reinicia continuamente, ver FREEIPA_TROUBLESHOOTING.md
