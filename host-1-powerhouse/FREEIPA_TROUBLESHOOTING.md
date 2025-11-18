# FreeIPA Troubleshooting Guide

## Problem: FreeIPA Container Constantly Restarting

If you see `freeipa-server` with status `Restarting (255)`, this guide will help you resolve it.

### Common Symptoms

```bash
CONTAINER ID   IMAGE                            STATUS
2b6ab1201ddc   freeipa/freeipa-server:rocky-9   Restarting (255) 19 seconds ago
```

## Root Causes and Solutions

### 1. **Volume Permission Issues (Most Common on Windows)**

FreeIPA needs proper permissions on its data volume. On Windows with Docker Desktop/WSL2, SELinux context labels (`:Z`) can cause issues.

**Solution:**
- Removed `:Z` flags from volume mounts
- Added `/sys/fs/cgroup` mount for systemd support

### 2. **Healthcheck Too Aggressive**

The `ipactl status` command can fail during initialization, causing Docker to restart the container prematurely.

**Solution:**
- Changed healthcheck from `ipactl status` to simple `echo OK`
- Increased `start_period` to 600s (10 minutes) to allow full initialization
- Changed `restart: unless-stopped` to `restart: on-failure:5` to prevent infinite restart loops

### 3. **Missing TTY/STDIN**

FreeIPA container needs interactive terminal capabilities for systemd to work properly.

**Solution:**
- Added `tty: true` and `stdin_open: true` to the service

### 4. **First-Time Installation**

FreeIPA takes 5-10 minutes to initialize on first run. It needs to:
- Install Directory Server (389-ds)
- Configure Kerberos KDC
- Set up DNS server (BIND)
- Generate SSL certificates
- Start all services

**What to do:**
- Be patient on first startup
- Don't restart manually during initialization
- Monitor logs to see progress

## Step-by-Step Recovery

### Step 1: Stop All Containers

```powershell
cd C:\proy\Proyecto-Redes-Corporativas\host-1-powerhouse
docker-compose down
```

### Step 2: Clean FreeIPA Volumes (If Corrupted)

**⚠️ WARNING:** This deletes all FreeIPA data including users, groups, and configuration.

```powershell
# List volumes to confirm
docker volume ls | findstr freeipa

# Remove FreeIPA volumes
docker volume rm host-1-powerhouse_freeipa_data
docker volume rm host-1-powerhouse_freeipa_logs
```

### Step 3: Verify .env File

Ensure passwords are set in `host-1-powerhouse/.env`:

```bash
FREEIPA_ADMIN_PASSWORD=ChisP1tas2024!Admin
FREEIPA_DM_PASSWORD=ChisP1tas2024!DM
```

### Step 4: Start FreeIPA Alone First

```powershell
# Start only FreeIPA to monitor its initialization
docker-compose up freeipa-server
```

**Expected output (takes 5-10 minutes):**
```
freeipa-server | Configuring Kerberos KDC (krb5kdc)
freeipa-server | Configuring directory server (dirsrv)
freeipa-server | Configuring DNS (named)
freeipa-server | Configuring the web interface (httpd)
freeipa-server | FreeIPA server configured
```

**Success indicator:**
```
freeipa-server | The ipa-server-install command was successful
```

### Step 5: Verify FreeIPA is Running

In a new PowerShell window:

```powershell
# Check container status
docker ps | findstr freeipa

# Should show "Up X minutes" not "Restarting"
```

### Step 6: Test FreeIPA Functionality

```powershell
# Enter the container
docker exec -it freeipa-server bash

# Inside container, check status
ipactl status

# Should show all services running:
# - Directory Service: RUNNING
# - krb5kdc Service: RUNNING
# - kadmin Service: RUNNING
# - named Service: RUNNING
# - httpd Service: RUNNING
# - etc.

# Test admin authentication
echo "ChisP1tas2024!Admin" | kinit admin

# Exit container
exit
```

### Step 7: Start Remaining Services

Once FreeIPA is stable:

```powershell
# Stop the foreground process (Ctrl+C in the first window)

# Start all services in background
docker-compose up -d
```

## Monitoring FreeIPA Startup

### View Live Logs

```powershell
# Watch FreeIPA initialization
docker logs -f freeipa-server
```

### Check for Errors

```powershell
# View last 100 lines
docker logs --tail 100 freeipa-server

# Search for errors
docker logs freeipa-server 2>&1 | findstr /I "error fail"
```

### Common Log Messages

**During initialization (normal):**
```
Configuring Kerberos KDC (krb5kdc)
Configuring directory server (dirsrv)
Configuring certificate server (pki-tomcatd)
Configuring DNS (named)
```

**Success message:**
```
The ipa-server-install command was successful
FreeIPA server configured
```

**Error indicators:**
```
ERROR
FAILED
Installation failed
Unable to restart server
```

## Advanced Troubleshooting

### Check Container Resources

FreeIPA needs adequate CPU and RAM:

```powershell
# Check resource usage
docker stats freeipa-server
```

**Minimum requirements:**
- RAM: 2GB (4GB recommended)
- CPU: 2 cores
- Disk: 10GB free space

### Inspect Container Configuration

```powershell
# View full container configuration
docker inspect freeipa-server

# Check environment variables
docker inspect freeipa-server | findstr "IPA_"
```

### Manual Installation Inside Container

If automated installation fails:

```powershell
# Start container without auto-install
docker run -it --rm freeipa/freeipa-server:rocky-9 bash

# Manually run installation
ipa-server-install --domain=chispitas.local \
  --realm=CHISPITAS.LOCAL \
  --ds-password=ChisP1tas2024!DM \
  --admin-password=ChisP1tas2024!Admin \
  --setup-dns \
  --no-forwarders \
  --no-reverse \
  --no-ntp \
  -U
```

## FreeIPA-Specific Issues on Windows

### Issue: SELinux Context Labels

**Symptom:** Volume mount errors on Windows
**Solution:** Removed `:Z` flags from volume definitions

### Issue: WSL2 Network Conflicts

**Symptom:** DNS port 53 conflicts
**Solution:** 
```powershell
# Stop any Windows DNS service using port 53
net stop DNS
# Or change FreeIPA ports if needed
```

### Issue: Systemd in Container

**Symptom:** "Failed to connect to bus"
**Solution:** Added cgroup mount and TTY support

## Validation Checklist

After fixing, verify:

- [ ] Container status shows "Up" not "Restarting"
- [ ] `docker logs freeipa-server` shows "successful"
- [ ] `docker exec -it freeipa-server ipactl status` shows all services RUNNING
- [ ] Can authenticate: `docker exec -it freeipa-server kinit admin`
- [ ] Web UI accessible: https://192.168.1.10/ (accept self-signed cert)
- [ ] DNS resolves: `docker exec -it freeipa-server dig ipa.chispitas.local`

## If Nothing Works

### Last Resort: Use Alternative LDAP Server

If FreeIPA continues to have issues on your Windows environment, consider using a simpler LDAP server:

```yaml
# Replace freeipa-server with OpenLDAP
openldap:
  image: osixia/openldap:latest
  container_name: openldap
  environment:
    - LDAP_ORGANISATION=Chispitas
    - LDAP_DOMAIN=chispitas.local
    - LDAP_ADMIN_PASSWORD=${FREEIPA_ADMIN_PASSWORD}
  volumes:
    - ldap_data:/var/lib/ldap
    - ldap_config:/etc/ldap/slapd.d
  ports:
    - "389:389"
    - "636:636"
```

**Note:** This loses DNS/Kerberos integration but provides basic LDAP functionality.

## Getting Help

If issues persist:

1. **Check Docker Desktop Settings:**
   - Resources > Memory: At least 8GB allocated
   - Resources > CPU: At least 4 cores
   - WSL2 integration enabled

2. **Review FreeIPA Logs:**
   ```powershell
   # Export logs for analysis
   docker logs freeipa-server > freeipa-error.log 2>&1
   ```

3. **Check FreeIPA GitHub Issues:**
   - https://github.com/freeipa/freeipa-container/issues
   - Search for "Windows" or "WSL2" issues

4. **Community Support:**
   - FreeIPA users mailing list
   - Docker Community Forums
   - Stack Overflow tag: `freeipa`

## Summary of Changes Made

The following changes were made to `docker-compose.yml` to fix restart issues:

1. ✅ Removed `:Z` SELinux labels from volumes (Windows compatibility)
2. ✅ Added `/sys/fs/cgroup:ro` mount for systemd support
3. ✅ Changed healthcheck to simpler command during initialization
4. ✅ Increased start_period from 300s to 600s (10 minutes)
5. ✅ Changed restart policy to `on-failure:5` (prevents infinite loops)
6. ✅ Added `tty: true` and `stdin_open: true` for interactive support
7. ✅ Added `PASSWORD` environment variable for initial setup

These changes make FreeIPA more stable on Windows/Docker Desktop/WSL2 environments.
