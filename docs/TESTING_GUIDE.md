# Testing and Validation Guide
## Proyecto: Chispitas - Fábrica de Momentos

Este documento describe todas las pruebas necesarias para validar el funcionamiento correcto de la infraestructura corporativa.

---

## Índice de Pruebas

1. [Pruebas de DNS](#1-pruebas-de-dns)
2. [Pruebas de Servidor de Correo](#2-pruebas-de-servidor-de-correo)
3. [Pruebas de Servidor de Archivos](#3-pruebas-de-servidor-de-archivos)
4. [Pruebas de Acceso Web](#4-pruebas-de-acceso-web)
5. [Pruebas de Autenticación LDAP](#5-pruebas-de-autenticación-ldap)
6. [Pruebas de Integración](#6-pruebas-de-integración)

---

## Preparación del Entorno de Pruebas

### Host-SVR-03 (Cliente de Pruebas)

Todas las pruebas deben ejecutarse desde **Host-SVR-03** (Lubuntu) que actúa como estación de auditoría.

**Verificar configuración:**

```bash
# Verificar DNS configurado
cat /etc/resolv.conf
# Debe contener: nameserver 192.168.1.10

# Verificar conectividad
ping 192.168.1.10  # FreeIPA
ping 192.168.1.20  # Correo/Archivos
ping 192.168.1.30  # Proxy (localhost)

# Verificar software de cliente instalado
which thunderbird
which smbclient
which dig
which ldapsearch
```

---

## 1. Pruebas de DNS

### Objetivo
Verificar que el servidor DNS de FreeIPA resuelve correctamente todos los nombres del dominio `chispitas.local`.

### Test 1.1: Resolución de Servicios Web

```bash
# Probar resolución de aplicaciones (deben apuntar al proxy: 192.168.1.30)
dig odoo.chispitas.local +short
# Esperado: 192.168.1.30

dig crm.chispitas.local +short
# Esperado: 192.168.1.30

dig hrm.chispitas.local +short
# Esperado: 192.168.1.30

dig erp.chispitas.local +short
# Esperado: 192.168.1.30
```

**Resultado Esperado:** Todas las consultas retornan `192.168.1.30`

**✓ PASS** / **✗ FAIL**

---

### Test 1.2: Resolución de Servicios de Infraestructura

```bash
# Servidor de correo (debe apuntar a Host-SVR-02)
dig mail.chispitas.local +short
# Esperado: 192.168.1.20

# Servidor de archivos
dig files.chispitas.local +short
# Esperado: 192.168.1.20

# Servidor FreeIPA
dig ipa.chispitas.local +short
# Esperado: 192.168.1.10
```

**Resultado Esperado:** Resolución correcta a las IPs correspondientes

**✓ PASS** / **✗ FAIL**

---

### Test 1.3: Registro MX (Correo)

```bash
# Verificar registro MX para el dominio
dig -t MX chispitas.local

# Salida esperada debe contener:
# chispitas.local.    IN  MX  10 mail.chispitas.local.
```

**Resultado Esperado:** Registro MX apuntando a `mail.chispitas.local` con prioridad 10

**✓ PASS** / **✗ FAIL**

---

### Test 1.4: Resolución Inversa (PTR)

```bash
# Opcional: Resolución inversa
dig -x 192.168.1.10
dig -x 192.168.1.20
dig -x 192.168.1.30
```

**Resultado Esperado:** Retorna los nombres FQDN correspondientes

**✓ PASS** / **✗ FAIL** (Opcional)

---

## 2. Pruebas de Servidor de Correo

### Objetivo
Verificar que el servidor de correo puede enviar y recibir correos entre usuarios, con autenticación LDAP.

### Preparación: Configurar Thunderbird

**Cuenta 1 - Luis Hernández:**

1. Abrir Thunderbird
2. Crear nueva cuenta de correo:
   - Nombre: Luis Hernández
   - Email: lhernandez@chispitas.local
   - Contraseña: User2Pass2024!
3. Configuración manual:
   - **Servidor Entrante (IMAP):**
     - Servidor: mail.chispitas.local
     - Puerto: 143
     - Seguridad: STARTTLS
     - Autenticación: Contraseña normal
     - Usuario: lhernandez
   - **Servidor Saliente (SMTP):**
     - Servidor: mail.chispitas.local
     - Puerto: 587
     - Seguridad: STARTTLS
     - Autenticación: Contraseña normal
     - Usuario: lhernandez

**Cuenta 2 - Jhon Molano:**

Repetir el proceso con:
- Email: jmolano@chispitas.local
- Usuario: jmolano
- Contraseña: User3Pass2024!

---

### Test 2.1: Envío de Correo

**Desde cuenta de jmolano:**

1. Redactar nuevo mensaje
2. Para: lhernandez@chispitas.local
3. Asunto: "Test 2.1: Envío de correo - Comercial a Producción"
4. Cuerpo: "Este es un mensaje de prueba del área Comercial al área de Producción."
5. Enviar

**Verificar:**
- No hay errores al enviar
- Mensaje aparece en carpeta "Enviados"

**Resultado Esperado:** Correo enviado exitosamente

**✓ PASS** / **✗ FAIL**

---

### Test 2.2: Recepción de Correo

**Desde cuenta de lhernandez:**

1. Actualizar bandeja de entrada (F5 o botón "Obtener mensajes")
2. Verificar que aparece el mensaje enviado en Test 2.1

**Verificar:**
- Mensaje recibido con asunto correcto
- Remitente es jmolano@chispitas.local
- Cuerpo del mensaje intacto

**Resultado Esperado:** Correo recibido correctamente

**✓ PASS** / **✗ FAIL**

---

### Test 2.3: Respuesta de Correo

**Desde cuenta de lhernandez:**

1. Abrir el mensaje recibido
2. Responder
3. Cuerpo: "Respuesta desde Producción. Mensaje recibido correctamente."
4. Enviar

**Desde cuenta de jmolano:**

1. Actualizar bandeja de entrada
2. Verificar respuesta recibida

**Resultado Esperado:** Flujo bidireccional de correo funciona

**✓ PASS** / **✗ FAIL**

---

### Test 2.4: Libreta de Direcciones LDAP (Opcional)

1. En Thunderbird: Herramientas → Libreta de direcciones
2. Archivo → Nuevo → Directorio LDAP
3. Configurar:
   - Nombre: Directorio Chispitas
   - Servidor: ipa.chispitas.local
   - Puerto: 389
   - Base DN: cn=users,cn=accounts,dc=chispitas,dc=local
4. Buscar contactos: escribir "klinares"

**Resultado Esperado:** Encuentra el usuario en el directorio

**✓ PASS** / **✗ FAIL** (Opcional)

---

## 3. Pruebas de Servidor de Archivos

### Objetivo
Verificar que el servidor Samba aplica correctamente los permisos basados en grupos de FreeIPA.

### Matriz de Permisos Esperada

| Usuario | Grupo | Produccion | Comercial | RRHH | Gerencia | Compartido |
|---------|-------|------------|-----------|------|----------|------------|
| lhernandez | GRP_Produccion | **RW** | ✗ | ✗ | ✗ | R |
| jmolano | GRP_Comercial | ✗ | **RW** | ✗ | ✗ | R |
| egonzales | GRP_RRHH | ✗ | ✗ | **RW** | ✗ | R |
| klinares | GRP_Admins_Dominio | RW | RW | RW | RW | RW |

*RW = Lectura/Escritura, R = Solo Lectura, ✗ = Sin Acceso*

---

### Test 3.1: Usuario de Producción - Acceso Permitido

**Usuario: lhernandez (GRP_Produccion)**

```bash
# Conectar al share de Producción
smbclient //files.chispitas.local/Produccion -U lhernandez
# Ingresar contraseña: User2Pass2024!

# Dentro del cliente SMB:
smb: \> ls
smb: \> mkdir test_lhernandez_produccion
smb: \> cd test_lhernandez_produccion
smb: \> put /etc/hosts test_file.txt
smb: \> ls
smb: \> rm test_file.txt
smb: \> cd ..
smb: \> rmdir test_lhernandez_produccion
smb: \> exit
```

**Resultado Esperado:** Todas las operaciones exitosas (crear, listar, escribir, borrar)

**✓ PASS** / **✗ FAIL**

---

### Test 3.2: Usuario de Producción - Acceso Denegado

**Usuario: lhernandez intentando acceder a Comercial**

```bash
# Intentar conectar al share Comercial
smbclient //files.chispitas.local/Comercial -U lhernandez
# Ingresar contraseña: User2Pass2024!

smb: \> mkdir test_acceso_denegado
# Salida esperada: NT_STATUS_ACCESS_DENIED
smb: \> exit
```

**Resultado Esperado:** Operación denegada con `NT_STATUS_ACCESS_DENIED`

**✓ PASS** / **✗ FAIL**

---

### Test 3.3: Usuario Comercial - Acceso Permitido

**Usuario: jmolano (GRP_Comercial)**

```bash
# Conectar al share Comercial
smbclient //files.chispitas.local/Comercial -U jmolano
# Ingresar contraseña: User3Pass2024!

smb: \> mkdir test_jmolano_comercial
smb: \> cd test_jmolano_comercial
smb: \> put /etc/hosts test_comercial.txt
smb: \> ls
smb: \> rm test_comercial.txt
smb: \> cd ..
smb: \> rmdir test_jmolano_comercial
smb: \> exit
```

**Resultado Esperado:** Todas las operaciones exitosas

**✓ PASS** / **✗ FAIL**

---

### Test 3.4: Usuario Comercial - Acceso Denegado a Producción

**Usuario: jmolano intentando acceder a Producción**

```bash
smbclient //files.chispitas.local/Produccion -U jmolano
smb: \> mkdir test_acceso_denegado
# Salida esperada: NT_STATUS_ACCESS_DENIED
smb: \> exit
```

**Resultado Esperado:** Operación denegada

**✓ PASS** / **✗ FAIL**

---

### Test 3.5: Share Compartido - Solo Lectura para Usuarios Estándar

**Usuario: lhernandez en share Compartido**

```bash
smbclient //files.chispitas.local/Compartido -U lhernandez

smb: \> ls
# Debe listar archivos existentes

smb: \> mkdir test_write_compartido
# Salida esperada: NT_STATUS_ACCESS_DENIED (solo admins pueden escribir)

smb: \> exit
```

**Resultado Esperado:** Puede listar, NO puede escribir

**✓ PASS** / **✗ FAIL**

---

### Test 3.6: Listar Shares Disponibles

```bash
# Listar todos los shares para lhernandez
smbclient -L //files.chispitas.local -U lhernandez

# Debe mostrar al menos:
# - Produccion (accesible)
# - Compartido (accesible)
# Y posiblemente otros shares (sin acceso)
```

**Resultado Esperado:** Lista de shares visible

**✓ PASS** / **✗ FAIL**

---

## 4. Pruebas de Acceso Web

### Objetivo
Verificar que el proxy inverso (Traefik) enruta correctamente el tráfico a todas las aplicaciones.

### Test 4.1: Acceso a Odoo Manufacturing

```bash
# Probar conectividad HTTP
curl -I http://odoo.chispitas.local

# Abrir en navegador
firefox http://odoo.chispitas.local &
```

**Resultado Esperado:**
- Código HTTP 200 OK o 303 (redirección)
- Página de login de Odoo visible en navegador

**✓ PASS** / **✗ FAIL**

---

### Test 4.2: Acceso a SuiteCRM

```bash
curl -I http://crm.chispitas.local
firefox http://crm.chispitas.local &
```

**Resultado Esperado:** Página de login de SuiteCRM

**✓ PASS** / **✗ FAIL**

---

### Test 4.3: Acceso a OrangeHRM

```bash
curl -I http://hrm.chispitas.local
firefox http://hrm.chispitas.local &
```

**Resultado Esperado:** Página de login de OrangeHRM

**✓ PASS** / **✗ FAIL**

---

### Test 4.4: Acceso a Dolibarr

```bash
curl -I http://erp.chispitas.local
firefox http://erp.chispitas.local &
```

**Resultado Esperado:** Página de login de Dolibarr

**✓ PASS** / **✗ FAIL**

---

### Test 4.5: Dashboard de Traefik

```bash
firefox http://traefik.chispitas.local &
# O
firefox http://192.168.1.30:8080 &
```

**Resultado Esperado:** Dashboard de Traefik mostrando todas las rutas configuradas

**✓ PASS** / **✗ FAIL**

---

## 5. Pruebas de Autenticación LDAP

### Objetivo
Verificar que FreeIPA está funcionando correctamente como servidor LDAP.

### Test 5.1: Query LDAP de Usuarios

```bash
# Buscar todos los usuarios
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <FREEIPA_ADMIN_PASSWORD> \
  -b "cn=users,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixAccount)" uid cn mail

# Debe mostrar klinares, lhernandez, jmolano, egonzales, etc.
```

**Resultado Esperado:** Lista de usuarios creados

**✓ PASS** / **✗ FAIL**

---

### Test 5.2: Query LDAP de Grupos

```bash
# Buscar todos los grupos
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <FREEIPA_ADMIN_PASSWORD> \
  -b "cn=groups,cn=accounts,dc=chispitas,dc=local" \
  "(objectClass=posixGroup)" cn member

# Debe mostrar GRP_Produccion, GRP_Comercial, etc.
```

**Resultado Esperado:** Lista de grupos con sus miembros

**✓ PASS** / **✗ FAIL**

---

### Test 5.3: Verificar Membresía de Grupo

```bash
# Verificar que lhernandez está en GRP_Produccion
ldapsearch -x -H ldap://192.168.1.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w <FREEIPA_ADMIN_PASSWORD> \
  -b "cn=GRP_Produccion,cn=groups,cn=accounts,dc=chispitas,dc=local" \
  member

# Debe incluir: uid=lhernandez,cn=users,cn=accounts,dc=chispitas,dc=local
```

**Resultado Esperado:** Usuario es miembro del grupo correcto

**✓ PASS** / **✗ FAIL**

---

### Test 5.4: Autenticación LDAP (Bind Test)

```bash
# Intentar autenticarse como lhernandez
ldapwhoami -x -H ldap://192.168.1.10 \
  -D "uid=lhernandez,cn=users,cn=accounts,dc=chispitas,dc=local" \
  -w User2Pass2024!

# Salida esperada: dn:uid=lhernandez,cn=users,cn=accounts,dc=chispitas,dc=local
```

**Resultado Esperado:** Autenticación exitosa

**✓ PASS** / **✗ FAIL**

---

## 6. Pruebas de Integración

### Test 6.1: Autenticación Web con LDAP (Opcional)

**Configurar SuiteCRM para LDAP:**

1. Login como admin en http://crm.chispitas.local
2. Admin → LDAP Authentication
3. Configurar:
   - LDAP Server: ipa.chispitas.local
   - Port: 389
   - Base DN: cn=users,cn=accounts,dc=chispitas,dc=local
   - Bind DN: uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local
   - Bind Password: <FREEIPA_ADMIN_PASSWORD>
4. Guardar

**Probar login:**

1. Logout de SuiteCRM
2. Intentar login con:
   - Usuario: jmolano
   - Password: User3Pass2024!

**Resultado Esperado:** Login exitoso usando credenciales de FreeIPA

**✓ PASS** / **✗ FAIL** (Requiere configuración adicional)

---

### Test 6.2: Flujo Completo - Usuario Nuevo

**Crear usuario nuevo en FreeIPA:**

```bash
# En el contenedor de FreeIPA
docker exec -it freeipa-server bash

kinit admin
ipa user-add testuser \
  --first=Test --last=User \
  --email=testuser@chispitas.local \
  --password
# Ingresar password temporal

# Agregar a grupo
ipa group-add-member GRP_Comercial --users=testuser

exit
```

**Agregar a Samba:**

```bash
# En Host-SVR-02
docker exec -it samba-server bash
smbpasswd -a testuser
# Ingresar mismo password que FreeIPA
exit
```

**Probar acceso:**

```bash
# Desde Host-SVR-03
smbclient //files.chispitas.local/Comercial -U testuser
# Debe poder acceder

smbclient //files.chispitas.local/Produccion -U testuser
# Debe ser denegado
```

**Resultado Esperado:** Usuario nuevo funciona en todos los servicios

**✓ PASS** / **✗ FAIL**

---

## Resumen de Resultados

| # | Prueba | Resultado | Notas |
|---|--------|-----------|-------|
| 1.1 | DNS - Servicios Web | ☐ PASS ☐ FAIL | |
| 1.2 | DNS - Infraestructura | ☐ PASS ☐ FAIL | |
| 1.3 | DNS - Registro MX | ☐ PASS ☐ FAIL | |
| 2.1 | Correo - Envío | ☐ PASS ☐ FAIL | |
| 2.2 | Correo - Recepción | ☐ PASS ☐ FAIL | |
| 2.3 | Correo - Respuesta | ☐ PASS ☐ FAIL | |
| 3.1 | Samba - Acceso Permitido | ☐ PASS ☐ FAIL | |
| 3.2 | Samba - Acceso Denegado | ☐ PASS ☐ FAIL | |
| 3.3 | Samba - Comercial OK | ☐ PASS ☐ FAIL | |
| 3.4 | Samba - Comercial Denegado | ☐ PASS ☐ FAIL | |
| 3.5 | Samba - Compartido R/O | ☐ PASS ☐ FAIL | |
| 4.1 | Web - Odoo | ☐ PASS ☐ FAIL | |
| 4.2 | Web - SuiteCRM | ☐ PASS ☐ FAIL | |
| 4.3 | Web - OrangeHRM | ☐ PASS ☐ FAIL | |
| 4.4 | Web - Dolibarr | ☐ PASS ☐ FAIL | |
| 5.1 | LDAP - Usuarios | ☐ PASS ☐ FAIL | |
| 5.2 | LDAP - Grupos | ☐ PASS ☐ FAIL | |
| 5.3 | LDAP - Membresía | ☐ PASS ☐ FAIL | |
| 5.4 | LDAP - Autenticación | ☐ PASS ☐ FAIL | |

**Total PASS: ___ / 18**

**Porcentaje de Éxito: ____%**

---

## Criterios de Aceptación

Para que el sistema sea considerado **funcional y listo para producción**, debe cumplir:

- ✓ Todas las pruebas de DNS (1.1 - 1.3) deben pasar
- ✓ Todas las pruebas de Correo (2.1 - 2.3) deben pasar
- ✓ Todas las pruebas de Samba (3.1 - 3.5) deben pasar
- ✓ Todas las pruebas de Web (4.1 - 4.5) deben pasar
- ✓ Todas las pruebas de LDAP (5.1 - 5.4) deben pasar
- ✓ Mínimo 90% de éxito general

**Firma del Auditor: ___________________**

**Fecha: ___________________**
