# Architecture Overview
## Proyecto Chispitas: Fábrica de Momentos

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │
                                  │
                    ┌─────────────▼─────────────┐
                    │      Router/Gateway       │
                    │      192.168.1.1          │
                    └─────────────┬─────────────┘
                                  │
                                  │
            ┌─────────────────────┴─────────────────────┐
            │        LAN: 192.168.1.0/24                 │
            │                                             │
    ┌───────┴────────┐    ┌──────────────┐    ┌─────────┴────────┐
    │                │    │              │    │                  │
┌───▼────────────┐  ┌▼────────────┐  ┌──▼──────────┐  ┌────────▼───────┐
│  HOST-SVR-01   │  │ HOST-SVR-02 │  │ HOST-SVR-03 │  │    Clients     │
│ (Windows/WSL2) │  │   (MacOS)   │  │  (Lubuntu)  │  │ (Workstations) │
│ 192.168.1.10   │  │192.168.1.20 │  │192.168.1.30 │  │ 192.168.1.x    │
└────────────────┘  └─────────────┘  └─────────────┘  └────────────────┘
         │                 │                 │
         │                 │                 │
    ┌────▼────┐       ┌────▼────┐       ┌───▼────┐
    │ Docker  │       │ Docker  │       │ Docker │
    │ Network │       │ Network │       │ Network│
    │172.20.  │       │172.20.  │       │172.20. │
    │0.0/16   │       │0.0/16   │       │0.0/16  │
    └────┬────┘       └────┬────┘       └───┬────┘
         │                 │                 │
         │                 │                 │
┌────────▼─────────┐  ┌───▼──────────┐  ┌───▼────────┐
│   CONTAINERS     │  │ CONTAINERS   │  │ CONTAINERS │
│                  │  │              │  │            │
│ • FreeIPA        │  │ • Mailserver │  │ • Traefik  │
│   172.20.1.10    │  │   172.20.2.10│  │   172.20   │
│   (LDAP/DNS/CA)  │  │   (Postfix/  │  │   .3.10    │
│                  │  │    Dovecot)  │  │   (Reverse │
│ • PostgreSQL     │  │              │  │    Proxy)  │
│   172.20.1.20    │  │ • Samba      │  │            │
│   (Odoo DB)      │  │   172.20.2.20│  └────────────┘
│                  │  │   (File Srv) │
│ • Odoo           │  │              │
│   172.20.1.21    │  └──────────────┘
│   (Manufacturing)│
│                  │
│ • MariaDB (CRM)  │
│   172.20.1.30    │
│                  │
│ • SuiteCRM       │
│   172.20.1.31    │
│   (Commercial)   │
│                  │
│ • MariaDB (HRM)  │
│   172.20.1.40    │
│                  │
│ • OrangeHRM      │
│   172.20.1.41    │
│   (HR System)    │
│                  │
│ • MariaDB (ERP)  │
│   172.20.1.50    │
│                  │
│ • Dolibarr       │
│   172.20.1.51    │
│   (Finance/Admin)│
│                  │
└──────────────────┘
```

---

## Service Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                          USER ACCESS FLOW                             │
└──────────────────────────────────────────────────────────────────────┘

1. WEB ACCESS:
   Client → http://odoo.chispitas.local
      ↓
   DNS (FreeIPA @ 192.168.1.10) resolves to 192.168.1.30
      ↓
   Traefik Proxy (192.168.1.30) receives request
      ↓
   Traefik routes to Odoo container (192.168.1.10:8069)
      ↓
   User accesses Odoo application

2. EMAIL ACCESS:
   Thunderbird → mail.chispitas.local
      ↓
   DNS resolves to 192.168.1.20
      ↓
   Mail Server (Postfix/Dovecot)
      ↓
   LDAP Authentication against FreeIPA
      ↓
   Email sent/received

3. FILE ACCESS:
   smbclient → \\files.chispitas.local\Produccion
      ↓
   DNS resolves to 192.168.1.20
      ↓
   Samba File Server
      ↓
   LDAP Authentication against FreeIPA
      ↓
   Group-based permissions applied
      ↓
   File access granted/denied
```

---

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              CENTRALIZED AUTHENTICATION (FreeIPA)                │
└─────────────────────────────────────────────────────────────────┘

┌────────────┐
│   FreeIPA  │
│ (Master)   │
│ - LDAP     │◄──────────┐
│ - Kerberos │           │
│ - DNS      │           │ LDAP Queries
│ - CA       │           │ Authentication
└──────┬─────┘           │
       │                 │
       │ Provides:       │
       │ • Users         │
       │ • Groups        │
       │ • Passwords     │
       │ • Policies      │
       │                 │
       ├─────────────────┼────────────────┐
       │                 │                │
       ▼                 ▼                ▼
┌─────────────┐   ┌────────────┐   ┌──────────┐
│ Mail Server │   │   Samba    │   │   Apps   │
│             │   │            │   │          │
│ Uses LDAP   │   │ Uses LDAP  │   │ (Optional│
│ for user    │   │ for user   │   │  LDAP    │
│ auth        │   │ auth and   │   │  auth)   │
│             │   │ group perms│   │          │
└─────────────┘   └────────────┘   └──────────┘
```

---

## Network Segmentation

```
┌────────────────────────────────────────────────────────────────┐
│                    NETWORK SEGMENTS                             │
└────────────────────────────────────────────────────────────────┘

Physical LAN: 192.168.1.0/24
├── Host-SVR-01: 192.168.1.10 (Infrastructure Core)
├── Host-SVR-02: 192.168.1.20 (Communication Services)
├── Host-SVR-03: 192.168.1.30 (Edge/Gateway)
└── Clients: 192.168.1.100-254 (User Workstations)

Docker Network: 172.20.0.0/16
├── 172.20.1.0/24 - Host-SVR-01 Services
│   ├── .10 - FreeIPA
│   ├── .20-.29 - Databases
│   ├── .30-.59 - Applications
│   └── (Reserved for expansion)
│
├── 172.20.2.0/24 - Host-SVR-02 Services
│   ├── .10 - Mail Server
│   ├── .20 - Samba
│   └── .30 - (Reserved - FreeIPA Replica)
│
└── 172.20.3.0/24 - Host-SVR-03 Services
    └── .10 - Traefik Proxy
```

---

## Data Flow

```
┌────────────────────────────────────────────────────────────────┐
│                       DATA PERSISTENCE                          │
└────────────────────────────────────────────────────────────────┘

Host-SVR-01:
├── freeipa_data         → FreeIPA configuration and certificates
├── postgres_odoo_data   → Odoo database
├── odoo_data            → Odoo application data
├── mariadb_crm_data     → SuiteCRM database
├── suitecrm_data        → SuiteCRM files
├── mariadb_hrm_data     → OrangeHRM database
├── orangehrm_data       → OrangeHRM files
├── mariadb_erp_data     → Dolibarr database
├── dolibarr_data        → Dolibarr application
└── dolibarr_documents   → Dolibarr documents

Host-SVR-02:
├── mailserver_data      → Email storage
├── mailserver_state     → Mail server state
├── samba_produccion     → Production share
├── samba_comercial      → Commercial share
├── samba_rrhh           → HR share
├── samba_gerencia       → Management share
└── samba_compartido     → Shared files

Host-SVR-03:
├── traefik_config       → Traefik configuration
└── traefik_acme         → SSL certificates
```

---

## Service Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPENDENCY GRAPH                              │
└─────────────────────────────────────────────────────────────────┘

Level 1 (Foundation):
┌─────────────────┐
│    FreeIPA      │ ← Must start first
└────────┬────────┘
         │
         │ Provides DNS, LDAP, Kerberos
         │
Level 2 (Databases):          ├──────────────────┐
┌──────────┐  ┌──────────┐    │                  │
│PostgreSQL│  │ MariaDB  │    │                  │
└────┬─────┘  └────┬─────┘    │                  │
     │             │           │                  │
     │             │           │                  │
Level 3 (Applications):       │                  │
┌────▼─────┐  ┌───▼──────┐   │                  │
│   Odoo   │  │SuiteCRM  │   │                  │
│          │  │OrangeHRM │   │                  │
│          │  │Dolibarr  │   │                  │
└──────────┘  └──────────┘    │                  │
                               │                  │
Level 2 (Infrastructure):      │                  │
                         ┌─────▼─────┐     ┌─────▼─────┐
                         │   Mail    │     │  Samba    │
                         │  Server   │     │   File    │
                         │           │     │  Server   │
                         └───────────┘     └───────────┘

Level 4 (Gateway):
                         ┌─────────────────┐
                         │    Traefik      │
                         │  Reverse Proxy  │
                         └─────────────────┘
```

---

## Technology Stack

### Infrastructure Layer

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Container Platform | Docker | Latest | Application containerization |
| Orchestration | Docker Compose | v2.x | Multi-container orchestration |
| Network | Docker Bridge | - | Container networking |
| Reverse Proxy | Traefik | 2.10 | HTTP routing and SSL |

### Identity & Access Management

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Directory Service | FreeIPA | Rocky 9 | LDAP directory |
| Authentication | Kerberos | (via FreeIPA) | SSO authentication |
| DNS | BIND | (via FreeIPA) | Domain name resolution |
| Certificate Authority | Dogtag | (via FreeIPA) | PKI/SSL certificates |

### Communication Services

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| SMTP Server | Postfix | Latest | Mail transport |
| IMAP/POP3 | Dovecot | Latest | Mail delivery |
| Mail Container | docker-mailserver | Latest | Mail stack integration |
| File Server | Samba | Latest | CIFS/SMB file sharing |

### Business Applications

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| ERP (Manufacturing) | Odoo | 17.0 | Production management |
| CRM | SuiteCRM | Latest | Customer relations |
| HRM | OrangeHRM | Latest | Human resources |
| ERP (Finance) | Dolibarr | Latest | Financial management |

### Database Layer

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| RDBMS (Odoo) | PostgreSQL | 15 | Relational database |
| RDBMS (Apps) | MariaDB | 10.11 | Relational database |

---

## Deployment Model

```
┌──────────────────────────────────────────────────────────────────┐
│                   DEPLOYMENT STRATEGY                             │
└──────────────────────────────────────────────────────────────────┘

Deployment Type: Multi-Host Distributed
Deployment Method: Docker Compose (per host)
Infrastructure: Bare Metal / Physical Hosts

Host Distribution Strategy:
┌─────────────────────────────────────────────────────────────────┐
│ Host-SVR-01: Application Tier                                   │
│ - High CPU/RAM (Ryzen 5, 32GB)                                  │
│ - Runs compute-intensive applications                           │
│ - Hosts FreeIPA (critical service)                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Host-SVR-02: Communication Tier                                 │
│ - Medium resources (M4, 16GB+)                                  │
│ - Runs communication services                                   │
│ - Mail and File servers                                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Host-SVR-03: Edge/Gateway Tier                                  │
│ - Low resources (E1, 4GB)                                       │
│ - Entry point for all web traffic                              │
│ - Client testing station                                        │
└─────────────────────────────────────────────────────────────────┘

Scalability Options:
- Add more application hosts (Host-SVR-04, 05...)
- Deploy FreeIPA replica on Host-SVR-02
- Implement load balancing in Traefik
- Migrate to Kubernetes for auto-scaling
```

---

## Security Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     SECURITY LAYERS                               │
└──────────────────────────────────────────────────────────────────┘

Layer 1: Network Security
├── LAN isolation (192.168.1.0/24)
├── Firewall rules per host
└── Docker network isolation (172.20.0.0/16)

Layer 2: Access Control
├── FreeIPA centralized authentication
├── LDAP group-based permissions
├── Kerberos ticket-based access
└── Role-based access control (RBAC)

Layer 3: Application Security
├── Traefik as reverse proxy
├── SSL/TLS encryption (self-signed CA)
├── Application-level authentication
└── Session management

Layer 4: Data Security
├── Docker volume encryption (optional)
├── Database user permissions
├── Samba share ACLs
└── Regular backups

Security Groups (FreeIPA):
├── GRP_Admins_Dominio    → Full access
├── GRP_Gerencia          → Management data
├── GRP_Produccion        → Production files/apps
├── GRP_Comercial         → Sales data/CRM
├── GRP_RRHH              → HR confidential data
├── GRP_Administrativo    → Financial data
└── GRP_Usuarios_Estandar → Basic access
```

---

## Backup Strategy

```
┌──────────────────────────────────────────────────────────────────┐
│                   BACKUP RECOMMENDATIONS                          │
└──────────────────────────────────────────────────────────────────┘

Critical Data (Daily):
├── FreeIPA data (freeipa_data volume)
├── PostgreSQL database (pg_dump)
├── MariaDB databases (mysqldump)
└── Samba shares (rsync)

Configuration (Weekly):
├── docker-compose.yml files
├── .env files (encrypted)
├── Service configuration files
└── Traefik dynamic configuration

Full System (Monthly):
├── Complete volume snapshots
├── Container images
└── Host system configuration

Backup Commands:
# FreeIPA backup
docker run --rm -v freeipa_data:/data \
  -v ./backups:/backup alpine \
  tar czf /backup/freeipa-$(date +%Y%m%d).tar.gz /data

# PostgreSQL backup
docker exec postgres-odoo pg_dump -U odoo_user odoo_db \
  > backups/odoo-$(date +%Y%m%d).sql

# MariaDB backup
docker exec mariadb-crm mysqldump -u root -p<pass> suitecrm_db \
  > backups/crm-$(date +%Y%m%d).sql

# Samba backup
rsync -avz /var/lib/docker/volumes/samba_produccion/_data/ \
  ./backups/samba-produccion/
```

---

## Monitoring & Maintenance

```
┌──────────────────────────────────────────────────────────────────┐
│               MONITORING RECOMMENDATIONS                          │
└──────────────────────────────────────────────────────────────────┘

Container Health:
- Monitor: docker ps -a
- Check: docker stats
- Logs: docker logs -f <container>

Service Health:
- FreeIPA: ipactl status
- Mail: postqueue -p, doveadm user list
- Samba: smbstatus
- Traefik: Dashboard at :8080

Resource Monitoring:
- CPU/RAM usage per host
- Disk space utilization
- Network bandwidth
- Container restart counts

Log Management:
- Centralized logging (optional: ELK stack)
- Log rotation
- Error alerting

Regular Maintenance Tasks:
- Update container images (monthly)
- Review security logs (weekly)
- Test backups (monthly)
- Update passwords (quarterly)
- Review user access (quarterly)
```

---

## Production Deployment Checklist

- [ ] Change all default passwords in .env
- [ ] Configure proper SSL certificates (Let's Encrypt or FreeIPA CA)
- [ ] Enable HTTPS redirect in Traefik
- [ ] Configure firewall rules on all hosts
- [ ] Set up regular backup automation
- [ ] Configure log rotation
- [ ] Enable monitoring/alerting
- [ ] Document custom configurations
- [ ] Train users on system access
- [ ] Prepare disaster recovery plan
- [ ] Test complete system failure/recovery
- [ ] Configure email relay (if needed)
- [ ] Set up DNS forwarders in FreeIPA
- [ ] Harden SSH access
- [ ] Review and apply security updates

---

## Future Enhancements

### Short Term
- Implement FreeIPA replica on Host-SVR-02
- Configure LDAP authentication in all web apps
- Set up automated backups
- Implement proper SSL certificates from FreeIPA CA

### Medium Term
- Add pfSense firewall container
- Implement VPN access for remote users
- Add monitoring solution (Prometheus + Grafana)
- Implement centralized logging (ELK stack)

### Long Term
- Migrate to Kubernetes for better orchestration
- Implement high availability for critical services
- Add disaster recovery site
- Implement compliance monitoring (GDPR, etc.)

---

**Document Version:** 1.0  
**Last Updated:** November 2024  
**Authors:** Grupo 3-302 - Redes Corporativas
