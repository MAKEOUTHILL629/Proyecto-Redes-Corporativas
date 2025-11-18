# Configuración de SuiteCRM - Soluciones Alternativas

## Problema

SuiteCRM **no tiene una imagen Docker oficial** lista para usar en Docker Hub. Las opciones disponibles son:

## Solución 1: Usar EspoCRM (Recomendado para pruebas rápidas)

EspoCRM es una alternativa moderna y ligera a SuiteCRM con imagen Docker oficial.

### Pasos:

1. **Descomentar el servicio en docker-compose.yml:**
   
   Editar `host-1-powerhouse/docker-compose.yml` y descomentar la sección de suitecrm (actualmente comentada).

2. **Usar la imagen de EspoCRM:**
   ```yaml
   suitecrm:  # Mantener el nombre para compatibilidad
     image: espocrm/espocrm:latest
     # ... resto de configuración
   ```

3. **Iniciar el servicio:**
   ```bash
   docker-compose up -d suitecrm
   ```

4. **Acceder a la interfaz:**
   - URL: http://crm.chispitas.local o http://192.168.1.10:8081
   - Usuario: admin (configurado en .env)
   - Contraseña: valor de SUITECRM_ADMIN_PASSWORD en .env

## Solución 2: Instalar SuiteCRM manualmente en contenedor PHP

Si necesita usar SuiteCRM específicamente:

### Dockerfile personalizado:

Crear `host-1-powerhouse/suitecrm/Dockerfile`:

```dockerfile
FROM php:8.1-apache

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libonig-dev \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        zip \
        curl \
        xml \
        mbstring \
    && a2enmod rewrite

# Descargar SuiteCRM
WORKDIR /var/www/html
RUN curl -L -o suitecrm.zip https://github.com/salesagility/SuiteCRM/archive/refs/tags/v7.14.2.zip \
    && unzip suitecrm.zip \
    && mv SuiteCRM-*/* . \
    && rm -rf SuiteCRM-* suitecrm.zip \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80
```

### Actualizar docker-compose.yml:

```yaml
suitecrm:
  build: ./suitecrm
  container_name: suitecrm
  env_file:
    - ../.env
  networks:
    chispitas_net:
      ipv4_address: 172.20.1.31
  ports:
    - "${SUITECRM_PORT:-8081}:80"
  environment:
    - PHP_MEMORY_LIMIT=512M
    - UPLOAD_MAX_FILESIZE=20M
  volumes:
    - suitecrm_data:/var/www/html
  depends_on:
    mariadb-crm:
      condition: service_healthy
  restart: unless-stopped
```

### Construir y ejecutar:

```bash
cd host-1-powerhouse
docker-compose build suitecrm
docker-compose up -d suitecrm
```

### Configuración inicial:

1. Acceder a http://192.168.1.10:8081
2. Seguir el instalador web:
   - Database Host: mariadb-crm
   - Database Name: suitecrm_db
   - Database User: suitecrm_user
   - Database Password: (valor de MARIADB_CRM_PASSWORD en .env)
   - Admin User: admin
   - Admin Password: (valor de SUITECRM_ADMIN_PASSWORD en .env)

## Solución 3: Usar Vtiger CRM (Alternativa con Docker)

Vtiger tiene imagen Docker disponible:

```yaml
suitecrm:  # Mantener nombre para compatibilidad
  image: vtigercrm/vtigercrm:latest
  container_name: suitecrm
  env_file:
    - ../.env
  networks:
    chispitas_net:
      ipv4_address: 172.20.1.31
  ports:
    - "${SUITECRM_PORT:-8081}:80"
  environment:
    - DB_HOSTNAME=mariadb-crm
    - DB_NAME=${MARIADB_CRM_DATABASE:-suitecrm_db}
    - DB_USERNAME=${MARIADB_CRM_USER:-suitecrm_user}
    - DB_PASSWORD=${MARIADB_CRM_PASSWORD}
  volumes:
    - suitecrm_data:/var/www/html
  depends_on:
    mariadb-crm:
      condition: service_healthy
  restart: unless-stopped
```

## Solución 4: Desplegar sin CRM (temporal)

Si solo necesita probar el resto de la infraestructura:

1. Dejar el servicio `suitecrm` comentado en docker-compose.yml
2. El servicio MariaDB para CRM seguirá creándose (útil para futuro)
3. Los demás servicios funcionarán normalmente

```bash
# Desplegar todo excepto CRM
docker-compose up -d
```

## Recomendación

Para este proyecto académico:

1. **Opción más rápida**: Usar EspoCRM (descomenta la sección en docker-compose.yml)
2. **Más cercano a SuiteCRM**: Construir imagen personalizada (Solución 2)
3. **Para producción real**: Evaluar EspoCRM, Vtiger, o construir SuiteCRM personalizado

## Soporte

Para más información:
- EspoCRM: https://github.com/espocrm/espocrm-docker
- SuiteCRM: https://github.com/salesagility/SuiteCRM
- Vtiger: https://hub.docker.com/r/vtigercrm/vtigercrm
