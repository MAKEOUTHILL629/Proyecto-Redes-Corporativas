#!/bin/bash
# Script para unir el servidor Samba al dominio FreeIPA
# Proyecto: Chispitas - Fábrica de Momentos

set -e

echo "=========================================="
echo "Samba Domain Join Script"
echo "Dominio: chispitas.local"
echo "=========================================="

# Configuración
DOMAIN="chispitas.local"
REALM="CHISPITAS.LOCAL"
IPA_SERVER="192.168.1.10"
ADMIN_USER="admin"

# Verificar conectividad con FreeIPA
echo ""
echo "1. Verificando conectividad con FreeIPA..."
if ping -c 2 $IPA_SERVER > /dev/null 2>&1; then
    echo "   ✓ Conectividad OK"
else
    echo "   ✗ Error: No se puede alcanzar FreeIPA en $IPA_SERVER"
    exit 1
fi

# Verificar resolución DNS
echo ""
echo "2. Verificando resolución DNS..."
if host $DOMAIN $IPA_SERVER > /dev/null 2>&1; then
    echo "   ✓ DNS OK"
else
    echo "   ⚠ Advertencia: DNS no resuelve correctamente"
fi

# Configurar LDAP password
echo ""
echo "3. Configurando contraseña LDAP en Samba..."
echo "   Ingrese la contraseña del administrador de FreeIPA cuando se solicite"
smbpasswd -w "$FREEIPA_ADMIN_PASSWORD"

# Probar conexión LDAP
echo ""
echo "4. Probando conexión LDAP..."
if ldapsearch -x -H ldap://$IPA_SERVER -D "uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local" -w "$FREEIPA_ADMIN_PASSWORD" -b "dc=chispitas,dc=local" "(objectClass=*)" > /dev/null 2>&1; then
    echo "   ✓ Conexión LDAP exitosa"
else
    echo "   ✗ Error en conexión LDAP"
    exit 1
fi

# Reiniciar Samba
echo ""
echo "5. Reiniciando servicios Samba..."
service smbd restart
service nmbd restart

echo ""
echo "=========================================="
echo "Configuración completada"
echo "=========================================="
echo ""
echo "PRÓXIMOS PASOS:"
echo "1. Crear usuarios en FreeIPA (si no existen)"
echo "2. Agregar usuarios al servidor Samba:"
echo "   smbpasswd -a <username>"
echo "3. Probar conexión desde cliente:"
echo "   smbclient -L //files.chispitas.local -U <username>"
echo ""
