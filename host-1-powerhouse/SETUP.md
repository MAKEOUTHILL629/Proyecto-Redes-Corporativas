# Instrucciones de Configuración Rápida - Host-SVR-01

## ⚠️ IMPORTANTE: Pre-requisitos

Antes de continuar, asegúrese de:

1. Tener Docker Desktop instalado y corriendo
2. Tener permisos de administrador/root
3. Tener al menos 20GB de espacio en disco libre

## Paso 1: Crear archivo .env

El archivo `.env` **YA ESTÁ INCLUIDO** en el repositorio con valores predeterminados. 

**IMPORTANTE**: Para seguridad, debe cambiar las contraseñas antes de usar en producción.

```bash
# Verificar que existe
cd C:\proy\Proyecto-Redes-Corporativas
dir .env

# Si no existe, crearlo desde el template
copy .env.template .env
```

### Editar contraseñas (RECOMENDADO)

```bash
# Editar el archivo
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

## Paso 2: Crear la red Docker

```bash
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

## Paso 3: Configurar SuiteCRM (OPCIONAL)

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

## Paso 4: Iniciar los servicios

```bash
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
docker-compose up -d
```

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

## Paso 5: Esperar inicialización de FreeIPA

FreeIPA tarda **5-10 minutos** en inicializarse por primera vez:

```bash
docker logs -f freeipa-server
# Esperar mensaje: "FreeIPA server configured."
# Presionar Ctrl+C para salir
```

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

**Causa**: El archivo `.env` no existe o está en la ubicación incorrecta.

**Solución**: 
```bash
# Verificar ubicación del .env
cd C:\proy\Proyecto-Redes-Corporativas
dir .env

# Si no existe
copy .env.template .env
```

El archivo `.env` debe estar en `C:\proy\Proyecto-Redes-Corporativas\.env`, NO en `host-1-powerhouse\.env`.

### Error: "network chispitas_net not found"

**Solución**: 
```bash
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

### Error: "pull access denied for salesagility/suitecrm"

**Causa**: La imagen de SuiteCRM no existe en Docker Hub.

**Solución**: El servicio de SuiteCRM ahora está comentado por defecto. Ver `SUITECRM_SETUP.md` para alternativas.

### Error: "Cannot find path ... because it does not exist"

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

## Notas Adicionales

- **Primera vez**: Los contenedores tardan más tiempo en iniciar mientras descargan las imágenes
- **FreeIPA**: Es el servicio más importante y el que más tarda en inicializar
- **Recursos**: Asegúrese de tener al menos 8GB RAM disponibles
- **Firewall**: Windows puede solicitar permisos para Docker - permitir acceso
