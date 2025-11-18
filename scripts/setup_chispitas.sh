#!/bin/bash
# ==============================================================================
# Script de Configuración de FreeIPA para Chispitas: Fábrica de Momentos
# ==============================================================================
# Este script puebla el directorio FreeIPA con la estructura organizacional
# completa: grupos de seguridad, usuarios de prueba y configuración DNS
#
# Basado en el estudio de factibilidad RC302_Grupo3_FactibilidadProyecto.pdf
# Grupo 3-302: Kevin Linares, Luis Hernández, Jhon Molano, Eber Gonzales
# ==============================================================================

set -e  # Salir en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# ==============================================================================
# INICIO DEL SCRIPT
# ==============================================================================

print_section "Script de Configuración de FreeIPA - Chispitas"
echo "Dominio: chispitas.local"
echo "Realm: CHISPITAS.LOCAL"
echo ""

# Verificar que estamos autenticados como admin
print_info "Verificando autenticación..."
if ! klist &>/dev/null; then
    print_error "No está autenticado. Ejecute: kinit admin"
    exit 1
fi
print_success "Autenticado correctamente"

# ==============================================================================
# FASE 1: CREAR GRUPOS DE SEGURIDAD
# ==============================================================================

print_section "FASE 1: Creando Grupos de Seguridad"

# Array de grupos a crear
# Basado en la sección 5.3 del estudio de factibilidad
declare -A GRUPOS=(
    ["GRP_Admins_Dominio"]="Administradores del Dominio - Acceso total"
    ["GRP_Gerencia"]="Gerencia - Dirección Ejecutiva"
    ["GRP_Produccion"]="Producción - Área de Manufactura"
    ["GRP_Comercial"]="Comercial - Marketing y Ventas"
    ["GRP_RRHH"]="Recursos Humanos - Gestión de Personal"
    ["GRP_Administrativo"]="Administrativo - Área Financiera"
    ["GRP_Usuarios_Estandar"]="Usuarios Estándar - Permisos Básicos"
    ["GRP_TI"]="Tecnologías de Información - Soporte Técnico"
)

for grupo in "${!GRUPOS[@]}"; do
    print_info "Creando grupo: $grupo"
    if ipa group-add "$grupo" --desc="${GRUPOS[$grupo]}" &>/dev/null; then
        print_success "Grupo $grupo creado exitosamente"
    else
        print_warning "Grupo $grupo ya existe o hubo un error"
    fi
done

# ==============================================================================
# FASE 2: CREAR USUARIOS DE PRUEBA
# ==============================================================================

print_section "FASE 2: Creando Usuarios de Prueba"

# Función para crear usuario
create_user() {
    local username=$1
    local firstname=$2
    local lastname=$3
    local email=$4
    local password=$5
    local groups=$6
    
    print_info "Creando usuario: $username ($firstname $lastname)"
    
    # Crear usuario
    if ipa user-add "$username" \
        --first="$firstname" \
        --last="$lastname" \
        --email="$email" \
        --homedir="/home/$username" \
        --shell="/bin/bash" \
        --password &>/dev/null <<EOF
$password
$password
EOF
    then
        print_success "Usuario $username creado"
    else
        print_warning "Usuario $username ya existe"
    fi
    
    # Agregar a grupos
    IFS=',' read -ra GRUP_ARRAY <<< "$groups"
    for grupo in "${GRUP_ARRAY[@]}"; do
        if ipa group-add-member "$grupo" --users="$username" &>/dev/null; then
            print_success "  ↳ Agregado al grupo: $grupo"
        else
            print_warning "  ↳ Ya es miembro de: $grupo"
        fi
    done
}

# Usuario 1: Kevin Justinn Linares Romero (Administrador del Dominio)
create_user \
    "klinares" \
    "Kevin" \
    "Linares" \
    "klinares@chispitas.local" \
    "User1Pass2024!" \
    "GRP_Admins_Dominio,GRP_TI"

# Usuario 2: Luis Felipe Hernández Chica (Área de Producción)
create_user \
    "lhernandez" \
    "Luis" \
    "Hernandez" \
    "lhernandez@chispitas.local" \
    "User2Pass2024!" \
    "GRP_Produccion,GRP_Usuarios_Estandar"

# Usuario 3: Jhon Fredy Molano Galindo (Área Comercial)
create_user \
    "jmolano" \
    "Jhon" \
    "Molano" \
    "jmolano@chispitas.local" \
    "User3Pass2024!" \
    "GRP_Comercial,GRP_Usuarios_Estandar"

# Usuario 4: Eber Santiago Gonzales Castillo (Recursos Humanos)
create_user \
    "egonzales" \
    "Eber" \
    "Gonzales" \
    "egonzales@chispitas.local" \
    "User4Pass2024!" \
    "GRP_RRHH,GRP_Usuarios_Estandar"

# Usuario adicional: Gerente General
create_user \
    "ggeneral" \
    "Gerente" \
    "General" \
    "ggeneral@chispitas.local" \
    "GerentePass2024!" \
    "GRP_Gerencia,GRP_Usuarios_Estandar"

# Usuario adicional: Contador
create_user \
    "contador" \
    "Contador" \
    "Principal" \
    "contador@chispitas.local" \
    "ContadorPass2024!" \
    "GRP_Administrativo,GRP_Usuarios_Estandar"

# ==============================================================================
# FASE 3: CONFIGURAR DNS
# ==============================================================================

print_section "FASE 3: Configurando Registros DNS"

# Función para agregar registro DNS A
add_dns_a_record() {
    local hostname=$1
    local ip=$2
    
    print_info "Agregando registro A: $hostname -> $ip"
    if ipa dnsrecord-add chispitas.local "$hostname" --a-rec="$ip" &>/dev/null; then
        print_success "Registro A creado: $hostname"
    else
        print_warning "Registro A ya existe: $hostname"
    fi
}

# Registros A para servicios web (apuntan al proxy en Host-SVR-03)
add_dns_a_record "odoo" "192.168.1.30"
add_dns_a_record "crm" "192.168.1.30"
add_dns_a_record "hrm" "192.168.1.30"
add_dns_a_record "erp" "192.168.1.30"
add_dns_a_record "traefik" "192.168.1.30"

# Registros A para servicios de infraestructura (Host-SVR-02)
add_dns_a_record "mail" "192.168.1.20"
add_dns_a_record "files" "192.168.1.20"

# Registros A para hosts
add_dns_a_record "svr-powerhouse" "192.168.1.10"
add_dns_a_record "svr-infra" "192.168.1.20"
add_dns_a_record "svr-edge" "192.168.1.30"

# Registro MX para correo
print_info "Agregando registro MX para correo"
if ipa dnsrecord-add chispitas.local @ --mx-rec="10 mail.chispitas.local." &>/dev/null; then
    print_success "Registro MX creado"
else
    print_warning "Registro MX ya existe"
fi

# Registros PTR (reverso) - opcional
print_info "Agregando registros PTR (reverso)"
# Nota: Esto requiere zona de reverso configurada
# ipa dnsrecord-add 1.168.192.in-addr.arpa. 10 --ptr-rec="ipa.chispitas.local." &>/dev/null || true

# ==============================================================================
# FASE 4: CONFIGURACIÓN ADICIONAL
# ==============================================================================

print_section "FASE 4: Configuración Adicional"

# Configurar políticas de contraseña (opcional)
print_info "Configurando política de contraseñas"
ipa pwpolicy-mod --minlength=8 --minclasses=3 --maxlife=180 --minlife=1 &>/dev/null || true
print_success "Política de contraseñas configurada"

# Configurar política de Kerberos
print_info "Configurando política de Kerberos"
ipa krbtpolicy-mod --maxlife=86400 --maxrenew=604800 &>/dev/null || true
print_success "Política de Kerberos configurada"

# ==============================================================================
# FASE 5: VERIFICACIÓN
# ==============================================================================

print_section "FASE 5: Verificación de Configuración"

# Listar grupos
print_info "Grupos creados:"
ipa group-find --all | grep "Group name:" | awk '{print "  - " $3}'

# Listar usuarios
print_info "Usuarios creados:"
ipa user-find --all | grep "User login:" | awk '{print "  - " $3}'

# Verificar registros DNS
print_info "Registros DNS A:"
ipa dnsrecord-find chispitas.local --a-rec 192.168 2>/dev/null | grep "Record name:" | awk '{print "  - " $3}' || true

print_info "Registro DNS MX:"
ipa dnsrecord-show chispitas.local @ 2>/dev/null | grep "MX record:" || true

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================

print_section "CONFIGURACIÓN COMPLETADA"

echo ""
echo -e "${GREEN}✓ Grupos de seguridad creados${NC}"
echo -e "${GREEN}✓ Usuarios de prueba creados${NC}"
echo -e "${GREEN}✓ Registros DNS configurados${NC}"
echo -e "${GREEN}✓ Políticas del dominio configuradas${NC}"
echo ""

print_section "INFORMACIÓN DE USUARIOS"

echo ""
echo "Credenciales de Usuarios de Prueba:"
echo "===================================="
echo ""
echo "1. Kevin Linares (Administrador):"
echo "   Usuario: klinares"
echo "   Password: User1Pass2024!"
echo "   Grupos: GRP_Admins_Dominio, GRP_TI"
echo ""
echo "2. Luis Hernández (Producción):"
echo "   Usuario: lhernandez"
echo "   Password: User2Pass2024!"
echo "   Grupos: GRP_Produccion, GRP_Usuarios_Estandar"
echo ""
echo "3. Jhon Molano (Comercial):"
echo "   Usuario: jmolano"
echo "   Password: User3Pass2024!"
echo "   Grupos: GRP_Comercial, GRP_Usuarios_Estandar"
echo ""
echo "4. Eber Gonzales (RRHH):"
echo "   Usuario: egonzales"
echo "   Password: User4Pass2024!"
echo "   Grupos: GRP_RRHH, GRP_Usuarios_Estandar"
echo ""

print_section "PRÓXIMOS PASOS"

echo ""
echo "1. Configurar el servidor de correo para usar LDAP"
echo "   - Host: ipa.chispitas.local"
echo "   - Base DN: cn=users,cn=accounts,dc=chispitas,dc=local"
echo ""
echo "2. Configurar Samba para usar LDAP"
echo "   - Ejecutar script de join domain en Host-SVR-02"
echo "   - Agregar usuarios Samba: smbpasswd -a <username>"
echo ""
echo "3. Probar resolución DNS desde clientes:"
echo "   dig odoo.chispitas.local"
echo "   dig -t MX chispitas.local"
echo ""
echo "4. Configurar aplicaciones web (Odoo, SuiteCRM, etc.) para LDAP"
echo "   - LDAP Server: ldap://ipa.chispitas.local"
echo "   - Base DN: cn=users,cn=accounts,dc=chispitas,dc=local"
echo "   - Bind DN: uid=admin,cn=users,cn=accounts,dc=chispitas,dc=local"
echo ""
echo "5. Realizar pruebas de auditoría desde Host-SVR-03"
echo "   - Ver README.md de host-3-edge para procedimientos"
echo ""

print_section "FIN DEL SCRIPT"

exit 0
