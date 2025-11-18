# Nota sobre Archivos .env

## Distribución de Archivos de Configuración

Este proyecto incluye archivos `.env` con valores predeterminados seguros para desarrollo/pruebas en las siguientes ubicaciones:

```
Proyecto-Redes-Corporativas/
├── .env                     # Archivo maestro (copiado a los hosts)
├── .env.template            # Template de referencia
├── host-1-powerhouse/
│   └── .env                 # Copia local para Docker Compose
├── host-2-infra/
│   └── .env                 # Copia local para Docker Compose
└── host-3-edge/
    └── .env                 # Copia local para Docker Compose
```

## ¿Por qué en múltiples ubicaciones?

Docker Compose busca el archivo `.env` en el **directorio actual** (donde se ejecuta `docker-compose up`), no en directorios padres. Esto es especialmente importante en Windows/PowerShell.

### Comportamiento de Docker Compose:

```bash
# ❌ NO funciona de manera confiable en Windows:
host-1-powerhouse/
  docker-compose.yml (con env_file: ../.env)
.env (en directorio padre)

# ✅ SÍ funciona en todos los sistemas:
host-1-powerhouse/
  docker-compose.yml (sin env_file)
  .env (en el mismo directorio)
```

## Uso

### Para Desarrollo/Pruebas (Valores Predeterminados)

Los archivos `.env` ya están incluidos con contraseñas seguras para desarrollo:

```bash
cd host-1-powerhouse
docker-compose up -d  # Usa .env automáticamente
```

**No debería ver advertencias** sobre variables no configuradas.

### Para Producción (Contraseñas Personalizadas)

1. **Opción 1: Editar archivos .env directamente**
   ```bash
   cd host-1-powerhouse
   notepad .env
   # Cambiar todas las contraseñas
   docker-compose up -d
   ```

2. **Opción 2: Usar .env.local (recomendado)**
   ```bash
   cd host-1-powerhouse
   copy .env .env.local
   notepad .env.local
   # Cambiar contraseñas
   # Docker Compose carga .env.local después de .env
   docker-compose up -d
   ```

3. **Opción 3: Variables de entorno del sistema**
   ```bash
   # Windows PowerShell
   $env:POSTGRES_ODOO_PASSWORD="MiPasswordSeguro123!"
   docker-compose up -d
   ```

## Sincronización

Si modifica el archivo `.env` raíz, debe copiarlo a los directorios de host:

```bash
# Desde el directorio raíz
copy .env host-1-powerhouse\.env
copy .env host-2-infra\.env
copy .env host-3-edge\.env
```

O use el script de sincronización (si está disponible):

```bash
./scripts/sync-env.sh  # Linux/Mac
.\scripts\sync-env.ps1  # Windows
```

## Variables Críticas

Estas variables **DEBEN** tener valores antes de ejecutar docker-compose:

### FreeIPA
- `FREEIPA_ADMIN_PASSWORD` - Admin principal
- `FREEIPA_DM_PASSWORD` - Directory Manager

### Bases de Datos
- `POSTGRES_ODOO_PASSWORD` - PostgreSQL para Odoo
- `MARIADB_ROOT_PASSWORD` - Root de MariaDB
- `MARIADB_CRM_PASSWORD` - Base de datos CRM
- `MARIADB_HRM_PASSWORD` - Base de datos HRM
- `MARIADB_ERP_PASSWORD` - Base de datos ERP

### Aplicaciones
- `DOLIBARR_ADMIN_PASSWORD` - Administrador Dolibarr
- `SUITECRM_ADMIN_PASSWORD` - Administrador CRM (si se usa)

## Solución de Problemas

### "The 'VARIABLE' is not set. Defaulting to a blank string."

**Causa**: El archivo `.env` no existe en el directorio donde se ejecuta `docker-compose`.

**Solución**:
```bash
# Verificar que existe
cd host-1-powerhouse
dir .env

# Si no existe, copiarlo
copy ..\. env .env
```

### "Container X is unhealthy"

**Causa**: Variables de contraseña vacías causan que los contenedores no inicien.

**Solución**:
```bash
# Ver el contenido del .env
type .env | findstr PASSWORD

# Todas las variables PASSWORD deben tener valores
# Si están vacías, editar:
notepad .env
```

### Cambios no se aplican

**Causa**: Docker Compose cachea las variables de entorno.

**Solución**:
```bash
# Detener contenedores
docker-compose down

# Reiniciar (carga .env nuevamente)
docker-compose up -d
```

## Seguridad

⚠️ **IMPORTANTE**:

1. **NO** commit archivos `.env` con contraseñas de producción a Git
2. Use `.env.local` o `.env.production` para producción (están en .gitignore)
3. Los valores predeterminados son **solo para desarrollo/pruebas**
4. Cambie **todas las contraseñas** antes de usar en producción
5. Considere usar un gestor de secretos (Vault, AWS Secrets Manager, etc.) para producción

## Valores Predeterminados Incluidos

Los archivos `.env` incluidos tienen estas contraseñas de desarrollo:

```
FREEIPA_ADMIN_PASSWORD=ChispitasAdmin2024!
FREEIPA_DM_PASSWORD=ChispitasDM2024!
POSTGRES_ODOO_PASSWORD=OdooSecurePass2024!
MARIADB_ROOT_PASSWORD=ChispitasRoot2024!
MARIADB_CRM_PASSWORD=CRMSecurePass2024!
MARIADB_HRM_PASSWORD=HRMSecurePass2024!
MARIADB_ERP_PASSWORD=ERPSecurePass2024!
DOLIBARR_ADMIN_PASSWORD=DolibarrAdmin2024!
```

**Estas son contraseñas de EJEMPLO** - cámbielas para cualquier uso que no sea desarrollo local.
