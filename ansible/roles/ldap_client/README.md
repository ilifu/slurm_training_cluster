# LDAP Client Role

This role configures LDAP client authentication on cluster nodes, enabling centralized user management and SSH key authentication through the LDAP directory.

## Description

The LDAP client role configures nodes to authenticate users against the central LDAP server. It sets up SSSD and nslcd for LDAP integration, configures SSH to retrieve public keys from LDAP, and enables automatic home directory creation. This allows users created in LDAP to login to any node in the cluster.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- Functional LDAP server accessible over network
- SSH daemon for key-based authentication
- Network connectivity to LDAP server

## Role Variables

### Required Variables
- `ldap_host` - LDAP server hostname/IP address
- `ldap_dns_domain_name` - DNS domain name for LDAP base DN construction
- `ldap_password` - LDAP admin password (for ldap.secret file)

### Optional Variables
- `timezone` - System timezone (inherited from base role)

### Derived Variables
- Base DN is automatically constructed from domain name (e.g., "training.ilifu.ac.za" → "dc=training,dc=ilifu,dc=ac,dc=za")

## Features

### Authentication Integration
- **SSSD Configuration** - Primary authentication via System Security Services Daemon
- **nslcd Configuration** - Name Service LDAP Connection Daemon for user/group lookups
- **NSSwitch Integration** - Configures system to check LDAP for users and groups
- **TLS Security** - Configured for non-TLS LDAP connections (training environment)

### SSH Key Management
- **LDAP SSH Keys** - Retrieves SSH public keys from LDAP directory
- **AuthorizedKeysCommand** - Configures SSH to query LDAP for user keys
- **Key Validation** - SSH keys stored in LDAP sshPublicKey attribute

### Home Directory Management
- **Automatic Creation** - Home directories created on first login
- **PAM Integration** - Uses pam_mkhomedir for directory creation
- **Shared Storage** - Works with CephFS mounted `/users` directory

### Name Service Configuration
- **User Resolution** - Maps LDAP users to local system accounts
- **Group Resolution** - Resolves LDAP groups for access control
- **Caching Disabled** - Prevents stale user/group information

## Dependencies

- **ldap_server** - Requires functioning LDAP server
- **base** - System base configuration
- **ceph** - Often used with shared home directories

## Example Playbook

```yaml
- hosts: cluster_nodes
  become: yes
  roles:
    - role: ldap_client
      vars:
        ldap_host: "ldap.training.ilifu.ac.za"
        ldap_dns_domain_name: "training.ilifu.ac.za"
        ldap_password: "{{ vault_ldap_admin_password }}"
```

## Configuration Files

### SSSD Configuration (`/etc/sssd/sssd.conf`)
- **Provider Configuration** - LDAP for id, auth, and chpass
- **Connection Settings** - Non-TLS connection to LDAP server
- **Caching** - Credential caching enabled for offline access

### nslcd Configuration (`/etc/nslcd.conf`)
- **Server URI** - LDAP server connection details
- **Base DN** - Search base for user/group queries
- **SSL Settings** - Configured for non-TLS operation

### NSSwitch Configuration (`/etc/nsswitch.conf`)
- **User Resolution Order** - files, systemd, sss, ldap
- **Group Resolution Order** - files, systemd, sss, ldap

## SSH Integration

The role configures SSH to retrieve public keys from LDAP:

```bash
# SSH configuration in /etc/ssh/sshd_config
AuthorizedKeysCommand /usr/local/bin/get_ssh_key_from_ldap.sh
AuthorizedKeysCommandUser nobody
```

This allows users to login with SSH keys stored in their LDAP account without needing local authorized_keys files.

## Troubleshooting

### Common Issues
- **Authentication Failures**: Check LDAP server connectivity and credentials
- **SSH Key Issues**: Verify keys are properly stored in LDAP sshPublicKey attribute
- **Home Directory Problems**: Ensure CephFS is mounted and pam_mkhomedir is configured

### Useful Commands
```bash
# Test LDAP user lookup
getent passwd username

# Test SSH key retrieval
/usr/local/bin/get_ssh_key_from_ldap.sh username

# Check SSSD status
sudo systemctl status sssd

# Monitor LDAP authentication
sudo tail -f /var/log/auth.log
```

### Service Management
```bash
# Restart authentication services
sudo systemctl restart sssd
sudo systemctl restart nslcd
sudo systemctl restart nscd
```

## Tags

- `ldap` - General LDAP client configuration
- `sssd` - SSSD-specific configuration
- `nslcd` - nslcd daemon configuration
- `nsswitch` - Name service switch configuration  
- `nscd` - Name service cache daemon configuration
- `authorizedkeys` - SSH key retrieval setup
- `pam` - PAM configuration for home directories
- `cert` - Certificate management
- `build` - Tasks run during image building

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
