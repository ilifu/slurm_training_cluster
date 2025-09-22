# LDAP Server Role

This role configures an OpenLDAP server (slapd) for centralized authentication and user management in the SLURM training cluster.

## Description

The LDAP server provides centralized user authentication and directory services for the cluster. It supports SSH public key storage, user account management, and integrates with SLURM for account provisioning. The server is configured with self-signed SSL certificates and includes the SSH public key schema for key-based authentication.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- OpenSSL for certificate generation
- Network connectivity from client nodes
- Sufficient storage for user directory data

## Role Variables

### Required Variables
- `ldap_organisation` - LDAP organization name (e.g., "Training Cluster")
- `ldap_dns_domain_name` - DNS domain name (e.g., "training.ilifu.ac.za")
- `ldap_password` - Admin password for cn=admin,dc=... account

### Optional Variables
- `timezone` - System timezone (default: Africa/Johannesburg)

### Derived Variables
- `dcs` - LDAP base DN (automatically derived from domain name: dc=training,dc=ilifu,dc=ac,dc=za)

## Features

### LDAP Server Configuration
- **OpenLDAP Installation** - Complete slapd server setup with required packages
- **SSL/TLS Support** - Self-signed certificate generation with proper permissions
- **SSH Key Schema** - Integrated openssh-lpk schema for SSH public key storage
- **Organization Setup** - Configurable organization and domain structure

### Certificate Management
- **Self-Signed Certificates** - Automatic generation of SSL certificates
- **Proper Permissions** - Certificates configured with correct ownership (openldap:openldap)
- **CA Certificate Integration** - System-wide certificate installation

### Directory Structure
- **Users OU** - Organizational unit for user accounts (ou=users)
- **Default Group** - Training group with GID 20000 (cn=training,ou=users)
- **Admin Account** - Configurable admin password with SSHA hashing

### Network Configuration
- **Multiple Protocols** - Supports ldap://, ldapi://, and ldaps:// protocols
- **Port Configuration** - Standard LDAP ports (389 for ldap, 636 for ldaps)

## Dependencies

None - this is a foundational service for the cluster.

## Example Playbook

```yaml
- hosts: ldap_server
  become: yes
  roles:
    - role: ldap_server
      vars:
        ldap_organisation: "CBIO Training Cluster"
        ldap_dns_domain_name: "training.ilifu.ac.za"
        ldap_password: "{{ vault_ldap_admin_password }}"
```

## Directory Schema

The server creates the following directory structure:

```
dc=training,dc=ilifu,dc=ac,dc=za
├── ou=users
│   ├── cn=training (posixGroup, gidNumber: 20000)
│   └── cn=username (user accounts added via add_user.py)
└── cn=admin (administrative account)
```

## SSL/TLS Configuration

The role configures SSL support with:
- Self-signed certificates in `/etc/ldap/sasl2/`
- Certificate authority integration
- Proper file permissions for OpenLDAP access
- LDAPS protocol support on port 636

## User Account Integration

User accounts are typically created via the `add_user.py` script on the head node, which:
- Creates posixAccount entries in ou=users
- Stores SSH public keys using the ldapPublicKey objectClass
- Assigns users to the default training group
- Sets up home directories in /users/

## Troubleshooting

### Common Issues
- **Certificate Problems**: Check ownership of `/etc/ldap/sasl2/` certificates
- **Connection Refused**: Verify slapd service is running and firewall allows port 389/636
- **Schema Errors**: Ensure openssh-lpk schema is properly loaded

### Useful Commands
```bash
# Test LDAP connectivity
ldapsearch -x -H ldap://localhost -b "dc=training,dc=ilifu,dc=ac,dc=za"

# Check slapd configuration
sudo slapcat -b cn=config

# Monitor slapd logs
sudo journalctl -u slapd -f
```

## Tags

- `ldap` - General LDAP configuration tasks
- `cert` - Certificate generation and SSL setup
- `ldap_password` - Password configuration tasks
- `ldap_ous` - Organizational unit creation
- `ldap_groups` - Group creation tasks
- `build` - Tasks run during image building

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
