# SLURM Head Node Role

This role configures the SLURM cluster head node (login node), providing user access, authentication, and comprehensive user management capabilities.

## Description

The SLURM head node serves as the primary access point for the cluster, handling user authentication through LDAP and providing tools for user account management. It includes SSH configuration, user management scripts, and passwordless sudo setup for administrators.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- LDAP server configured and accessible
- Python 3.10+ with pip/uv package manager
- SSH key-based access configured

## Role Variables

### SSH Configuration
- `password_login_enabled` - Enable/disable SSH password authentication (default: false)

### LDAP Integration  
- `ldap_host` - LDAP server hostname/IP
- `ldap_dns_domain_name` - LDAP domain name
- `dcs` - LDAP base DN (automatically derived from domain name)

### User Management
- User creation scripts are deployed to `~/bin/` for the ubuntu user
- Virtual environment with required Python packages (ldap3, coloredlogs, sshpubkeys)

## Features

### User Management System
- **`add_user.py`** - Comprehensive user creation script with:
  - Single user creation with LDAP and SLURM integration
  - Bulk user creation (user01, user02, etc.) with smart numbering
  - Dictionary-based random password generation (5 English words)
  - Admin user creation with passwordless sudo and SLURM admin privileges
  - SSH key validation and integration

### SLURM Integration
- **`init_slurm_accounts`** - System script to initialize SLURM accounting:
  - Creates default `training` account
  - Sets up ubuntu user with SLURM admin privileges
  - Configures accounting database

### Security Configuration
- **Passwordless Sudo Setup** - Creates `admin` group with NOPASSWD privileges
- **SSH Configuration** - Configurable password authentication
- **Agent Forwarding** - SSH agent forwarding enabled

### System Configuration
- **MOTD Customization** - Custom welcome message for SLURM cluster
- **Python Environment** - Isolated virtual environment for user management tools

## Dependencies

- **ldap_client** - Provides LDAP authentication and user resolution
- **slurm_common** - Provides base SLURM configuration
- **ceph** - Provides shared storage mounting for user directories

## Example Playbook

```yaml
- hosts: slurm_headnode
  become: yes
  roles:
    - role: slurm_headnode
      vars:
        password_login_enabled: false
        ldap_host: "ldap.training.ilifu.ac.za"
        ldap_dns_domain_name: "training.ilifu.ac.za"
```

## Usage

### Initialize SLURM Accounts
```bash
sudo /usr/local/bin/init_slurm_accounts
```

### Create Users
```bash
# Single user with SSH key
./add_user.py --make-changes -un john -n John -sn Doe --ssh-public-key "ssh-rsa ..."

# Admin user with random password  
./add_user.py --make-changes -un admin1 -n Admin -sn User --password RANDOM --admin

# Bulk creation of 10 training users
./add_user.py --make-changes --user_count 10
```

### Manage Existing Users
```bash
# Add admin privileges
sudo usermod -a -G admin username
sacctmgr modify user where name=username set adminlevel=Admin
```

## Tags

- `password_login` - SSH password authentication configuration
- `motd` - Message of the day setup
- `user_management` - User creation scripts and tools
- `sudo_config` - Passwordless sudo group configuration

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
