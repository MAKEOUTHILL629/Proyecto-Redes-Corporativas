-----

# Proyecto Final: Intranet Corporativa "Chispitas"

[cite\_start]Este repositorio contiene la configuración y los archivos de despliegue para el proyecto final de la materia **Redes Corporativas (302)** [cite: 9][cite\_start], de la carrera de **Ingeniería Telemática** [cite: 8] [cite\_start]en la **Universidad Distrital Francisco José de Caldas**[cite: 7].

[cite\_start]El objetivo es implementar una intranet corporativa completa y funcional para la empresa ficticia **"Chispitas: Fábrica de Momentos"**[cite: 2, 15], utilizando Docker para la orquestación de servicios distribuidos en un entorno de hardware híbrido.

[cite\_start]**Autores (Grupo 3-302):** [cite: 3]

  * [cite\_start]Kevin Justinn Linares Romero [cite: 4]
  * [cite\_start]Luis Felipe Hernández Chica [cite: 4]
  * [cite\_start]Jhon Fredy Molano Galindo [cite: 4]
  * [cite\_start]Eber Santiago Gonzales Castillo [cite: 4]

**Profesor:**

  * [cite\_start]Andrés Moncada Espitia [cite: 6]

-----

## 1\. Descripción del Proyecto

[cite\_start]Este proyecto es la implementación práctica del estudio de factibilidad técnica y económica para "Chispitas"[cite: 1, 12]. [cite\_start]Suple la necesidad crítica de la empresa de migrar de procesos manuales y sistemas aislados (como hojas de cálculo y WhatsApp) [cite: 297, 302, 331] a una plataforma empresarial integrada.

[cite\_start]La solución está 100% basada en software **Open Source** [cite: 820, 987] y se despliega mediante contenedores **Docker** para garantizar la portabilidad, escalabilidad y un rápido despliegue en la infraestructura de hardware mixto especificada.

## 2\. Características Principales

La intranet implementa una suite completa de servicios corporativos esenciales:

  * [cite\_start]**Directorio Activo y DNS Centralizado:** Se utiliza **FreeIPA** [cite: 89, 955] [cite\_start]para gestionar de forma centralizada todos los usuarios, grupos, políticas y permisos, siguiendo la estructura organizacional definida [cite: 224-253]. También actúa como el servidor DNS principal para todo el dominio `chispitas.local`.
  * [cite\_start]**Servidor de Correo Corporativo:** Un stack de correo con **Postfix** (SMTP) y **Dovecot** (IMAP/POP3)[cite: 958], totalmente integrado con el LDAP de FreeIPA para la autenticación de usuarios.
  * [cite\_start]**Servidor de Archivos (Samba):** Un servidor de archivos **Samba** [cite: 959] [cite\_start]unido al dominio de FreeIPA, proporcionando recursos compartidos de red con permisos granulares basados en los grupos del directorio (ej. `GRP_Produccion`, `GRP_Comercial`)[cite: 239, 243].
  * [cite\_start]**Suite de Aplicaciones de Productividad:** [cite: 27]
      * [cite\_start]**Odoo Manufacturing:** Para la gestión del área de Producción (Core de Negocio)[cite: 38, 907].
      * [cite\_start]**SuiteCRM:** Para el Área Comercial y Marketing[cite: 47, 141].
      * [cite\_start]**OrangeHRM:** Para el Área de Recursos Humanos[cite: 54, 173].
      * [cite\_start]**Dolibarr:** Para el Área Administrativa y Financiera[cite: 63, 185].
  * **Seguridad y Acceso a la Red:**
      * [cite\_start]Un firewall **pfSense** [cite: 925] actúa como puerta de enlace principal.
      * Un **Proxy Inverso** (Traefik/Nginx) gestiona todo el tráfico web y aplica certificados SSL (autofirmados por la CA de FreeIPA).
      * [cite\_start]La arquitectura simula la segmentación de red con VLANs (Admin, Producción, Comercial) como se define en el estudio [cite: 928-933].

## 3\. Arquitectura de Despliegue

Los servicios se distribuyen en tres máquinas anfitrionas (hosts) para simular un entorno de producción realista, balanceando la carga según los recursos de hardware disponibles.

### Distribución de Hosts

| Host Físico | Sistema Operativo | Recursos | Rol en el Proyecto | Servicios Desplegados |
| :--- | :--- | :--- | :--- | :--- |
| **Host 1: `SVR-POWERHOUSE`** | Windows 11 (WSL2) | Ryzen 5 7600x, 32GB RAM | **Servidor de Aplicaciones y BBDD** | Odoo, SuiteCRM, OrangeHRM, Dolibarr, Bases de Datos (PostgreSQL/MariaDB) |
| **Host 2: `SVR-INFRA`** | MacOS | M4, (RAM \> 16GB) | **Servidor de Infraestructura** | Servidor de Correo (Postfix/Dovecot), Servidor de Archivos (Samba) |
| **Host 3: `SVR-EDGE`** | Lubuntu | AMD E1, 4GB RAM | **Servidor de Borde y Pruebas** | Proxy Inverso (Traefik/Nginx), Firewall (pfSense), Cliente de Auditoría (Thunderbird, `smbclient`, etc.) |

### Diagrama de Red

[cite\_start]El despliegue sigue la arquitectura técnica validada en el estudio de factibilidad[cite: 919], utilizando Proxmox (conceptualizado aquí con Docker) para la virtualización de servicios y la segmentación de VLANs.

## 4\. Tecnologías Utilizadas

| Categoría | Software | Propósito |
| :--- | :--- | :--- |
| **Orquestación** | Docker & Docker Compose | Contenerización y despliegue de servicios. |
| **Directorio y DNS** | [cite\_start]**FreeIPA** [cite: 955] | Gestión central de identidades (LDAP/Kerberos) y DNS. |
| **Correo** | [cite\_start]Postfix, Dovecot [cite: 958] | Servidor de correo (SMTP, IMAP). |
| **Archivos** | [cite\_start]Samba [cite: 959] | Servidor de archivos compatible con Windows (CIFS/SMB). |
| **Aplicaciones** | [cite\_start]Odoo, SuiteCRM, OrangeHRM, Dolibarr [cite: 27] | Suite de productividad ERP/CRM/HRM. |
| **Bases de Datos** | PostgreSQL, MariaDB | Almacenamiento de datos para las aplicaciones. |
| [cite\_start]**Red** | pfSense[cite: 925], Traefik (o Nginx) | Firewall, Enrutamiento y Proxy Inverso. |

## 5\. Instalación y Despliegue

### Prerrequisitos

1.  Las tres máquinas host deben estar conectadas a la misma red LAN.
2.  Se recomienda asignar **IPs estáticas** a las tres máquinas host.
3.  **Docker** y **Docker-Compose** deben estar instalados y funcionales en los 3 hosts.
4.  Git, para clonar este repositorio.

### Pasos de Despliegue

1.  **Clonar el Repositorio:**

    ```bash
    git clone <url-del-repositorio>
    cd <nombre-del-repositorio>
    ```

2.  **Configurar Variables de Entorno:**

      * Edita el archivo `.env` principal. Define las IPs estáticas de tus hosts y las contraseñas maestras (especialmente `FPADMIN_PASSWORD` para FreeIPA).

3.  **Desplegar Host 1 (Windows/Powerhouse):**

      * Abre una terminal (PowerShell o CMD) en la carpeta del proyecto.
      * ```bash
        cd host-1-powerhouse
        docker-compose up -d
        ```

4.  **Desplegar Host 2 (MacOS/Infra):**

      * Abre una terminal en la carpeta del proyecto.
      * ```bash
        cd host-2-infra
        docker-compose up -d
        ```

5.  **Desplegar Host 3 (Lubuntu/Edge):**

      * Abre una terminal en la carpeta del proyecto.
      * ```bash
        cd host-3-edge
        docker-compose up -d
        ```

## 6\. Configuración Post-Instalación (Puesta en Marcha)

Una vez que todos los contenedores estén en ejecución, se debe poblar el directorio y configurar las integraciones.

1.  **Configurar Cliente de Pruebas (Host 3):**

      * Edita el archivo `/etc/resolv.conf` en el host de Lubuntu para que apunte al servidor DNS de FreeIPA (la IP de `SVR-POWERHOUSE`).
      * `nameserver <IP_HOST_1>`

2.  **Inicializar FreeIPA (en Host 1):**

      * Accede al contenedor de FreeIPA:
        ```bash
        docker exec -it freeipa-server /bin/bash
        ```
      * Autentica como administrador (la contraseña está en el `.env`):
        ```bash
        kinit admin
        ```
      * Ejecuta el script de poblamiento para crear la estructura de "Chispitas":
        ```bash
        ./setup_chispitas.sh
        ```
      * [cite\_start]Este script creará los grupos (ej. `GRP_Produccion`, `GRP_Comercial`) [cite: 239-253] y los usuarios de prueba.

3.  **Configurar DNS en FreeIPA:**

      * A través de la interfaz web de FreeIPA (`https://<IP_HOST_1>`) o por línea de comandos, crea los siguientes registros:
          * **Registros A:**
              * `odoo.chispitas.local` -\> `<IP_HOST_3>` (Proxy)
              * `crm.chispitas.local` -\> `<IP_HOST_3>` (Proxy)
              * `hrm.chispitas.local` -\> `<IP_HOST_3>` (Proxy)
              * `erp.chispitas.local` -\> `<IP_HOST_3>` (Proxy)
              * `mail.chispitas.local` -\> `<IP_HOST_2>` (Servidor de Correo)
              * `files.chispitas.local` -\> `<IP_HOST_2>` (Servidor de Archivos)
          * **Registro MX:**
              * [cite\_start]`chispitas.local.` -\> `mail.chispitas.local.` [cite: 1192]

4.  **Unir Samba al Dominio (en Host 2):**

      * Accede al contenedor de Samba: `docker exec -it samba-server /bin/bash`
      * Ejecuta el script para unirse al dominio (requerirá la contraseña de `admin` de FreeIPA).

## 7\. Plan de Auditoría y Validación (Checklist)

Realiza estas pruebas desde el **Host 3 (Lubuntu)** para simular la auditoría del profesor.

#### ✅ Prueba 1: Resolución de Nombres (DNS)

```bash
# Prueba de servicios web (deben apuntar al Proxy en Host 3)
dig crm.chispitas.local

# Prueba del servidor de correo (debe apuntar a Host 2)
dig mail.chispitas.local

# Prueba de registro MX (debe devolver mail.chispitas.local)
dig -t MX chispitas.local
```

#### ✅ Prueba 2: Servidor de Correo (SMTP/IMAP)

1.  Configura **Thunderbird** en Host 3 con dos cuentas de usuario creadas en FreeIPA (ej. `jmolano@chispitas.local` y `lhernandez@chispitas.local`).
2.  El servidor de entrada (IMAP) y salida (SMTP) es `mail.chispitas.local`.
3.  La autenticación debe ser `Kerberos / GSSAPI` o `Contraseña normal` (usando la contraseña de FreeIPA).
4.  **Prueba:** Envía un correo de `jmolano` a `lhernandez`. Verifica que llegue y que `lhernandez` pueda responder.

#### ✅ Prueba 3: Servidor de Archivos (Samba y Permisos)

  * [cite\_start]Se usarán los usuarios `lhernandez` (miembro de `GRP_Produccion`) y `jmolano` (miembro de `GRP_Comercial`)[cite: 4, 239, 243].

<!-- end list -->

1.  **Prueba de Usuario de Producción (`lhernandez`):**

    ```bash
    # Conectar al share de Producción (Debe tener éxito)
    smbclient //files.chispitas.local/Produccion -U 'lhernandez'
    > ls
    > mkdir prueba_produccion
    > exit

    # Conectar al share Comercial (Debe fallar)
    smbclient //files.chispitas.local/Comercial -U 'lhernandez'
    > mkdir prueba_comercial
    NT_STATUS_ACCESS_DENIED making remote directory \prueba_comercial
    ```

2.  **Prueba de Usuario Comercial (`jmolano`):**

    ```bash
    # Conectar al share Comercial (Debe tener éxito)
    smbclient //files.chispitas.local/Comercial -U 'jmolano'
    > ls
    > mkdir prueba_comercial
    > exit

    # Conectar al share de Producción (Debe fallar)
    smbclient //files.chispitas.local/Produccion -U 'jmolano'
    > mkdir prueba_produccion
    NT_STATUS_ACCESS_DENIED making remote directory \prueba_produccion
    ```

#### ✅ Prueba 4: Acceso a Aplicaciones Web (Proxy Inverso)

1.  Abre un navegador web en Host 3.
2.  Accede a `http://crm.chispitas.local`.
3.  Deberías ver la página de login de **SuiteCRM**.
4.  Accede a `http://odoo.chispitas.local`.
5.  Deberías ver la página de login de **Odoo**.
6.  (Opcional, si se configuró LDAP en las apps): Inicia sesión en SuiteCRM con el usuario `jmolano` y su contraseña de FreeIPA. El acceso debe ser exitoso.
