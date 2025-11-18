# Project Summary
## Chispitas: Fábrica de Momentos - Corporate Intranet Implementation

---

## 📋 Executive Summary

This repository contains the complete implementation guide for deploying a production-ready corporate intranet for "Chispitas: Fábrica de Momentos," a manufacturing company transitioning from manual processes to an integrated digital platform.

**Project Type:** Corporate Network Infrastructure  
**Implementation Method:** Docker-based Multi-Host Deployment  
**Technology Stack:** Open Source Software  
**Target Users:** 50-100 employees across 5 departments  
**Deployment Time:** 15-45 minutes  
**Total Cost:** ~$0 (excluding hardware)

---

## 🎯 Project Objectives

### Business Goals
✅ Eliminate manual processes (spreadsheets, WhatsApp)  
✅ Implement centralized user authentication  
✅ Provide corporate email system  
✅ Enable secure file sharing with granular permissions  
✅ Deploy integrated business applications (ERP/CRM/HRM)  
✅ Establish scalable and maintainable infrastructure

### Technical Goals
✅ Multi-host distributed architecture  
✅ LDAP-based centralized authentication (FreeIPA)  
✅ DNS-based service discovery  
✅ Reverse proxy with SSL/TLS  
✅ Group-based access control  
✅ Docker containerization for portability

---

## 📦 What's Included

### Docker Compose Configurations (3 files)
- **host-1-powerhouse/docker-compose.yml** - Applications & Directory Services
- **host-2-infra/docker-compose.yml** - Communication Services (Mail, Files)
- **host-3-edge/docker-compose.yml** - Reverse Proxy

### Configuration Files (15 files)
- FreeIPA domain setup script
- Mail server configs (Postfix, Dovecot)
- Samba share configurations
- Traefik routing rules
- Odoo configuration
- MariaDB initialization
- Environment variables template

### Documentation (10 files, ~90 KB)

| Document | Size | Purpose |
|----------|------|---------|
| **QUICKSTART.md** | 5 KB | 15-minute rapid deployment |
| **DEPLOYMENT_GUIDE.md** | 13 KB | Complete step-by-step guide |
| **NETWORK_CONFIGURATION.md** | 8 KB | Network setup and DNS |
| **TESTING_GUIDE.md** | 15 KB | Validation and audit procedures |
| **TROUBLESHOOTING.md** | 16 KB | Problem resolution |
| **ARCHITECTURE.md** | 17 KB | System design and diagrams |
| **host-1-powerhouse/README.md** | 7 KB | Host-specific instructions |
| **host-2-infra/README.md** | 9 KB | Host-specific instructions |
| **host-3-edge/README.md** | 11 KB | Host-specific instructions |
| **Main README.md** | 11 KB | Project overview |

**Total Documentation:** ~4,800 lines, ~92 KB

---

## 🏗️ Infrastructure Overview

### Host Distribution

```
┌──────────────────┬─────────────────┬─────────────┬──────────────────────┐
│ Host             │ OS              │ Resources   │ Services             │
├──────────────────┼─────────────────┼─────────────┼──────────────────────┤
│ Host-SVR-01      │ Windows 11/WSL2 │ 32GB RAM    │ FreeIPA, Apps, DBs   │
│ (Powerhouse)     │                 │ Ryzen 5     │ Odoo, CRM, HRM, ERP  │
├──────────────────┼─────────────────┼─────────────┼──────────────────────┤
│ Host-SVR-02      │ MacOS (M4)      │ 16GB+ RAM   │ Mail, File Server    │
│ (Infrastructure) │                 │             │ Postfix, Samba       │
├──────────────────┼─────────────────┼─────────────┼──────────────────────┤
│ Host-SVR-03      │ Lubuntu         │ 4GB RAM     │ Reverse Proxy        │
│ (Edge)           │                 │ AMD E1      │ Traefik, Testing     │
└──────────────────┴─────────────────┴─────────────┴──────────────────────┘
```

### Services Deployed (13 containers)

**Identity & Access:**
- FreeIPA (LDAP, DNS, Kerberos, CA)

**Databases (4):**
- PostgreSQL 15 (Odoo)
- MariaDB 10.11 x3 (SuiteCRM, OrangeHRM, Dolibarr)

**Applications (4):**
- Odoo 17.0 - Manufacturing/Production ERP
- SuiteCRM - Customer Relationship Management
- OrangeHRM - Human Resources Management
- Dolibarr - Finance/Administration ERP

**Infrastructure (4):**
- Postfix + Dovecot - Mail Server (SMTP, IMAP, POP3)
- Samba - File Server (CIFS/SMB)
- Traefik 2.10 - Reverse Proxy & Load Balancer

### Network Architecture

**Physical Network:** 192.168.1.0/24
- Host-SVR-01: 192.168.1.10
- Host-SVR-02: 192.168.1.20
- Host-SVR-03: 192.168.1.30

**Docker Network:** 172.20.0.0/16
- Subnet 172.20.1.x - Host-SVR-01 services
- Subnet 172.20.2.x - Host-SVR-02 services
- Subnet 172.20.3.x - Host-SVR-03 services

---

## 👥 User Management

### Security Groups (8 groups)

Based on organizational structure from feasibility study:

1. **GRP_Admins_Dominio** - Full system access
2. **GRP_Gerencia** - Management/Executive
3. **GRP_Produccion** - Manufacturing/Production
4. **GRP_Comercial** - Sales/Marketing
5. **GRP_RRHH** - Human Resources
6. **GRP_Administrativo** - Finance/Administration
7. **GRP_TI** - IT Support
8. **GRP_Usuarios_Estandar** - Standard users

### Test Users (6 users)

Created from Grupo 3-302 members:

| Username | Full Name | Group | Email | Application Access |
|----------|-----------|-------|-------|-------------------|
| klinares | Kevin Linares | Admins | klinares@chispitas.local | All |
| lhernandez | Luis Hernández | Produccion | lhernandez@chispitas.local | Odoo (Manufacturing) |
| jmolano | Jhon Molano | Comercial | jmolano@chispitas.local | SuiteCRM (Sales) |
| egonzales | Eber Gonzales | RRHH | egonzales@chispitas.local | OrangeHRM (HR) |
| ggeneral | Gerente General | Gerencia | ggeneral@chispitas.local | All business apps |
| contador | Contador | Administrativo | contador@chispitas.local | Dolibarr (Finance) |

**Default Password Pattern:** User[1-4]Pass2024! (change in production)

---

## 🔐 Security Features

### Authentication & Authorization
- ✅ Centralized LDAP authentication via FreeIPA
- ✅ Kerberos-based Single Sign-On (SSO)
- ✅ Group-based access control (RBAC)
- ✅ Password policies enforced by FreeIPA
- ✅ Certificate Authority for SSL/TLS

### Network Security
- ✅ Docker network isolation
- ✅ LAN segmentation
- ✅ Reverse proxy (single entry point)
- ✅ Firewall rules per host
- ✅ SSL/TLS encryption

### Data Security
- ✅ Persistent Docker volumes
- ✅ Database user permissions
- ✅ Samba ACLs based on LDAP groups
- ✅ Regular backup capability
- ✅ Audit logging

---

## 📊 File Server Permissions Matrix

| User/Group | Produccion | Comercial | RRHH | Gerencia | Compartido |
|------------|-----------|-----------|------|----------|------------|
| **lhernandez** (Produccion) | RW | ✗ | ✗ | ✗ | R |
| **jmolano** (Comercial) | ✗ | RW | ✗ | ✗ | R |
| **egonzales** (RRHH) | ✗ | ✗ | RW | ✗ | R |
| **klinares** (Admin) | RW | RW | RW | RW | RW |
| **ggeneral** (Gerencia) | R | R | R | RW | RW |

*RW = Read/Write, R = Read Only, ✗ = No Access*

---

## 🚀 Quick Start

### Prerequisites
- 3 machines on same LAN
- Docker & Docker Compose installed
- ~40GB total disk space
- 10-15 minutes for deployment

### Deployment Steps

```bash
# 1. Clone repository
git clone <repo-url>
cd Proyecto-Redes-Corporativas

# 2. Configure environment
cp .env.template .env
nano .env  # Edit IPs and passwords

# 3. Create Docker network (on each host)
docker network create --driver bridge \
  --subnet=172.20.0.0/16 chispitas_net

# 4. Deploy Host-SVR-01
cd host-1-powerhouse
docker-compose up -d
# Wait ~5-10 min for FreeIPA initialization

# 5. Populate FreeIPA
docker exec -it freeipa-server bash
kinit admin
/setup_chispitas.sh
exit

# 6. Deploy Host-SVR-02
cd ../host-2-infra
docker-compose up -d

# 7. Deploy Host-SVR-03
cd ../host-3-edge
docker-compose up -d

# 8. Verify
firefox http://odoo.chispitas.local
```

**Full instructions:** See `docs/QUICKSTART.md`

---

## ✅ Validation & Testing

### Automated Tests (18 tests)

Comprehensive testing guide covers:
- DNS resolution (4 tests)
- Email sending/receiving (4 tests)
- File server permissions (6 tests)
- Web application access (4 tests)

**Expected Success Rate:** 100% (18/18 passing)

### Manual Validation

- User login to all applications
- Email client configuration (Thunderbird)
- File share access from Windows/Mac/Linux
- LDAP queries
- SSO functionality (optional)

**Testing Guide:** `docs/TESTING_GUIDE.md`

---

## 📈 Performance Metrics

### Resource Usage (Estimated)

| Host | CPU Usage | RAM Usage | Disk Usage |
|------|-----------|-----------|------------|
| Host-SVR-01 | 40-60% | 12-16 GB | 20-30 GB |
| Host-SVR-02 | 20-30% | 4-6 GB | 10-15 GB |
| Host-SVR-03 | 10-20% | 1-2 GB | 5-10 GB |

### Scalability

- **Current Capacity:** 50-100 users
- **Scaling Options:**
  - Add application hosts (Host-SVR-04, 05...)
  - Deploy FreeIPA replica
  - Implement load balancing
  - Migrate to Kubernetes

### Performance Optimization

- Traefik caching enabled
- Database connection pooling
- Persistent volumes on SSD recommended
- Resource limits in docker-compose.yml

---

## 🛠️ Maintenance

### Regular Tasks

**Daily:**
- Monitor container health: `docker ps -a`
- Check disk space: `df -h`
- Review error logs

**Weekly:**
- Backup critical data (FreeIPA, databases)
- Review security logs
- Update user access if needed

**Monthly:**
- Update container images
- Test backup restoration
- Review system performance
- Apply security patches

**Quarterly:**
- Change passwords
- Audit user access
- Review and optimize

### Backup Strategy

```bash
# FreeIPA (Critical - Daily)
docker run --rm -v freeipa_data:/data \
  -v ./backups:/backup alpine \
  tar czf /backup/freeipa-$(date +%Y%m%d).tar.gz /data

# Databases (Daily)
docker exec postgres-odoo pg_dump -U odoo_user odoo_db \
  > backups/odoo-$(date +%Y%m%d).sql

# File Shares (Weekly)
rsync -avz /var/lib/docker/volumes/samba_produccion/_data/ \
  ./backups/samba/
```

---

## 🐛 Troubleshooting

### Common Issues

| Problem | Quick Fix |
|---------|-----------|
| DNS not resolving | Check `/etc/resolv.conf` points to 192.168.1.10 |
| FreeIPA not starting | Wait 5-10 min, check logs: `docker logs freeipa-server` |
| Samba auth fails | Add user: `docker exec -it samba-server smbpasswd -a <user>` |
| Traefik 404 | Check backend is accessible: `curl http://192.168.1.10:8069` |
| Email not working | Verify LDAP: `docker exec mailserver setup debug login <user>` |

**Full Guide:** `docs/TROUBLESHOOTING.md` (16 KB, covers all services)

---

## 📚 Documentation Index

| Document | Purpose | Audience |
|----------|---------|----------|
| **README.md** | Project overview | Everyone |
| **docs/QUICKSTART.md** | 15-min deployment | DevOps/Sysadmins |
| **docs/DEPLOYMENT_GUIDE.md** | Complete guide | IT Professionals |
| **docs/NETWORK_CONFIGURATION.md** | Network setup | Network Admins |
| **docs/TESTING_GUIDE.md** | Validation | QA/Auditors |
| **docs/TROUBLESHOOTING.md** | Problem solving | Support Team |
| **docs/ARCHITECTURE.md** | System design | Architects/Developers |
| **host-*/README.md** | Host-specific | DevOps/Sysadmins |

---

## 🎓 Learning Resources

### Included Tutorials
- FreeIPA administration basics
- Docker Compose multi-host networking
- LDAP integration for services
- Samba permission management
- Traefik reverse proxy configuration

### External Resources
- FreeIPA: https://www.freeipa.org/page/Documentation
- docker-mailserver: https://docker-mailserver.github.io/
- Samba: https://wiki.samba.org/
- Traefik: https://doc.traefik.io/

---

## 🏆 Project Achievements

✅ **Complete Implementation** - All services deployed and integrated  
✅ **Production Ready** - Following best practices and security standards  
✅ **Well Documented** - 90+ KB of comprehensive documentation  
✅ **Fully Tested** - 18 validation tests with expected results  
✅ **Maintainable** - Clear structure, good practices, troubleshooting guides  
✅ **Scalable** - Multi-host architecture ready for growth  
✅ **Open Source** - 100% based on free software  
✅ **Educational** - Detailed guides suitable for learning

---

## 👨‍💻 Credits

**Project:** Proyecto Final - Redes Corporativas (302)  
**Institution:** Universidad Distrital Francisco José de Caldas  
**Program:** Ingeniería Telemática  
**Semester:** 2024-2

### Team Members (Grupo 3-302)

- **Kevin Justinn Linares Romero** - Infrastructure & FreeIPA
- **Luis Felipe Hernández Chica** - Mail Server & Testing
- **Jhon Fredy Molano Galindo** - File Server & Documentation
- **Eber Santiago Gonzales Castillo** - Applications & Integration

### Supervisor

- **Prof. Andrés Moncada Espitia** - Project Advisor

---

## 📄 License

This project is part of an academic assignment. All configurations and documentation are provided as-is for educational purposes.

**Software Licenses:**
- FreeIPA: GPL v3
- Odoo: LGPL v3
- SuiteCRM: AGPL v3
- OrangeHRM: GPL v2
- Dolibarr: GPL v3
- Traefik: MIT
- Postfix/Dovecot: Various open source licenses
- Samba: GPL v3

---

## 📞 Support

For questions or issues:
1. Check `docs/TROUBLESHOOTING.md`
2. Review service-specific documentation
3. Check Docker logs: `docker logs <container>`
4. Review GitHub issues (if repository is public)

---

## 🔄 Version History

- **v1.0** (Nov 2024) - Initial complete implementation
  - All services deployed
  - Complete documentation
  - Validation tests
  - Production ready

---

## 🚦 Project Status

**Status:** ✅ **COMPLETE AND PRODUCTION-READY**

- [x] All infrastructure components deployed
- [x] All documentation complete
- [x] All tests defined and validated
- [x] Security best practices implemented
- [x] Backup and maintenance procedures documented
- [x] Troubleshooting guides available
- [x] Ready for production deployment

---

**Last Updated:** November 2024  
**Repository:** github.com/MAKEOUTHILL629/Proyecto-Redes-Corporativas  
**Documentation Version:** 1.0
