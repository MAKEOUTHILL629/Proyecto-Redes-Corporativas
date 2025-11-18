# Instrucciones de Configuración Rápida - Host-SVR-01

## Paso 1: Crear archivo .env

Antes de ejecutar `docker-compose up -d`, **DEBE** crear un archivo `.env` en el directorio raíz del proyecto (un nivel arriba de este directorio).

```bash
# Desde el directorio host-1-powerhouse
cd ..
cp .env.template .env
```

## Paso 2: Editar el archivo .env

Abra el archivo `.env` y configure al menos estas variables críticas:

```bash
# Editar el archivo (en Windows use notepad o un editor de texto)
notepad .env
# O en Linux/Mac
nano .env
```

**Variables mínimas requeridas:**
- `FREEIPA_ADMIN_PASSWORD` - Contraseña del administrador de FreeIPA
- `FREEIPA_DM_PASSWORD` - Contraseña del Directory Manager
- `POSTGRES_ODOO_PASSWORD` - Contraseña de la base de datos de Odoo
- `MARIADB_ROOT_PASSWORD` - Contraseña root de MariaDB
- `MARIADB_CRM_PASSWORD` - Contraseña para SuiteCRM
- `MARIADB_HRM_PASSWORD` - Contraseña para OrangeHRM
- `MARIADB_ERP_PASSWORD` - Contraseña para Dolibarr
- `SUITECRM_ADMIN_PASSWORD` - Contraseña admin de SuiteCRM
- `DOLIBARR_ADMIN_PASSWORD` - Contraseña admin de Dolibarr

## Paso 3: Crear la red Docker

```bash
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

## Paso 4: Iniciar los servicios

```bash
cd host-1-powerhouse
docker-compose up -d
```

## Notas Importantes

1. **Versión de Docker Compose**: La advertencia sobre `version: '3.8'` puede ignorarse - es obsoleta pero no causa problemas.

2. **Imágenes de Docker**: 
   - SuiteCRM usa `salesagility/suitecrm:latest` (la imagen bitnami/suitecrm no existe)
   - OrangeHRM usa `orangehrm/orangehrm:latest`
   - Dolibarr usa `dolibarr/dolibarr:latest`

3. **Primera vez**: FreeIPA tarda 5-10 minutos en inicializarse por primera vez.

4. **Logs**: Para ver el progreso:
   ```bash
   docker logs -f freeipa-server
   ```

## Solución de Problemas

### Error: "variable is not set"
**Causa**: No existe el archivo `.env` o está en la ubicación incorrecta.
**Solución**: El archivo `.env` debe estar en el directorio padre (un nivel arriba), no en `host-1-powerhouse/`.

### Error: "manifest not found"
**Causa**: La imagen de Docker especificada no existe.
**Solución**: Este error ha sido corregido. SuiteCRM ahora usa `salesagility/suitecrm:latest`.

### Error: "network chispitas_net not found"
**Causa**: La red Docker no ha sido creada.
**Solución**: 
```bash
docker network create --driver bridge --subnet=172.20.0.0/16 --gateway=172.20.0.1 chispitas_net
```

## Verificación

Para verificar que todo está funcionando:

```bash
# Ver todos los contenedores
docker ps

# Ver logs de un servicio específico
docker logs freeipa-server
docker logs odoo-manufacturing
docker logs suitecrm

# Verificar salud de los servicios
docker-compose ps
```
