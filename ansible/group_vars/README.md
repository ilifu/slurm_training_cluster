# Ansible Group Variables Reference

This directory contains Ansible group variables that configure the SLURM training cluster. Variables are organized by host group and can be overridden at multiple levels.

## Variable Precedence

Ansible applies variables in this order (later overrides earlier):
1. Role defaults (`roles/*/defaults/main.yml`)
2. Inventory variables
3. Group variables (`group_vars/*/`)
4. Host variables (`host_vars/*/`)
5. Play variables
6. Task variables

## Directory Structure

```
group_vars/
├── all/              # Variables for all hosts
│   └── main.yml      # Applied to every host
├── slurm/            # SLURM-specific variables (currently empty)
├── vault.yml         # Encrypted secrets (created by user)
└── README.md         # This file
```

## all/main.yml Variables

Variables defined for all hosts in the cluster:

### Software Versions

#### Go Language
```yaml
go:
  version: "1.25"                              # Go version
  url: "https://go.dev/dl/go1.25.4.linux-amd64.tar.gz"
  checksum: "sha256:..."                       # SHA256 checksum for verification
```

#### Singularity/Apptainer
```yaml
singularity:
  version: "4.3.4"                            # Singularity container engine version
  url: "https://github.com/sylabs/singularity/releases/..."
  checksum: "sha256:..."
```

#### High-Performance Computing Libraries

**UCX (Unified Communication X)**
```yaml
ucx:
  version: "1.19.0"                           # UCX version
  url: "https://github.com/openucx/ucx/releases/..."
  checksum: "sha256:..."
  dir: "/opt/ucx"                             # Installation directory
```

**OpenPMIX**
```yaml
pmix:
  version: "5.0.9"                            # OpenPMIX version
  url: "https://github.com/openpmix/openpmix/releases/..."
  checksum: "sha1:..."
```

**Open MPI**
```yaml
mpi:
  version: "5.0.8"                            # Open MPI version
  url: "https://download.open-mpi.org/release/..."
  checksum: "sha256:..."
```

### SLURM Configuration

```yaml
slurm:
  version: "25.11.0"                          # SLURM version to install
  version_git: "25-11-0-1"                    # Git tag for SLURM source
  db_name: "slurm_db"                         # Database name for accounting
  db_user: "slurm"                            # Database user account
  dbd_port: "7031"                            # SLURM database daemon port
  ctld_port: "6817"                           # SLURM controller port
  slurmd_port: "6818"                         # SLURM compute daemon port
  spool_dir: "/var/spool/slurmd"              # Spool directory for SLURM
  accounts:                                   # SLURM accounts for job submission
    training: "Basic account for training"    # Default account for cluster
```

**Understanding SLURM Accounts:**
- Accounts are billing units in SLURM
- Users must specify an account when submitting jobs: `sbatch -A training`
- Add more accounts by extending the accounts dictionary:
  ```yaml
  accounts:
    training: "Basic account for training"
    research: "Research projects"
    special: "Special compute allocation"
  ```

### Lmod Module System

```yaml
lmod:
  version: "9.0.2"                            # Lmod version
  url: "https://github.com/TACC/Lmod/archive/..."
  checksum: "sha256:..."
```

## Terraform-Generated Variables

When Terraform provisions infrastructure, it generates additional variables via `group_vars/all.yml` (created from `templates/group_vars_all.tpl`). These may include:

```yaml
# Infrastructure identifiers
cluster_name: "ilifu-training"                # Cluster name
domain_name: "example.com"                    # Domain for web services
ssh_key_location: "~/.ssh/id_rsa"            # SSH key for cluster access

# LDAP Configuration
ldap_host: "ldap.training.example.com"       # LDAP server hostname
ldap_dns_domain_name: "dc=example,dc=com"   # LDAP base DN
ldap_organisation_name: "ilifu"               # Organization name
ldap_password: "{{ vault_ldap_password }}"   # Reference to vault

# Database Configuration
database_host: "database.training.example.com" # MariaDB host
db_name: "slurm_db"                           # Database name
slurm_db_password: "{{ vault_slurm_db_password }}" # Reference to vault

# SLURM Configuration
slurm_username: "slurm"                       # SLURM system user
slurm_group_name: "slurm"                     # SLURM system group
controller_host: "controller.training.example.com" # Controller node

# Optional Feature Flags
install_docker: true                          # Install Docker on compute nodes
user_docker: false                            # Allow user Docker access
install_jupyterhub: true                      # Install JupyterHub
install_caddy: true                           # Install Caddy web server

# Storage Configuration
ceph_mounts:                                  # CephFS mount definitions
  home:
    name: "home"
    mount_point: "/users"
    export_locations: ["..."]
  data:
    name: "data"
    mount_point: "/data"
    export_locations: ["..."]
  software:
    name: "software"
    mount_point: "/software"
    export_locations: ["..."]
  scratch:
    name: "scratch"
    mount_point: "/scratch"
    export_locations: ["..."]
```

## Creating a Vault File

Sensitive credentials should be stored in an encrypted vault file:

```bash
# Create and edit encrypted vault file
ansible-vault create group_vars/vault.yml
```

**Example vault.yml contents:**

```yaml
---
# LDAP Secrets
vault_ldap_admin_password: "change_me_strong_password"

# SLURM Database Secrets
vault_slurm_db_password: "change_me_database_password"

# JupyterHub Secrets (if installed)
vault_jupyterhub_admin_password: "change_me_jupyter_password"

# Caddy Secrets (if installed)
vault_caddy_tls_email: "admin@example.com"
vault_caddy_admin_password: "change_me_caddy_password"
```

**Reference vault variables in other files:**

```yaml
# In group_vars/all.yml or role defaults:
ldap_password: "{{ vault_ldap_admin_password }}"
slurm_db_password: "{{ vault_slurm_db_password }}"
```

**Edit vault file:**

```bash
# Decrypt, edit, and re-encrypt
ansible-vault edit group_vars/vault.yml
```

## Variable Usage in Playbooks

### Referencing Variables

Variables can be referenced in templates and tasks using Jinja2 syntax:

```yaml
# In a task
- name: Use SLURM version variable
  debug:
    msg: "Installing SLURM version {{ slurm.version }}"

# In a template
SLURM_VERSION={{ slurm.version }}
SLURM_DB_NAME={{ slurm.db_name }}

# Nested variable access
{{ mpi.version }}
{{ go.checksum }}
```

### Conditional Variables

Use variables to enable/disable features:

```yaml
# In site.yaml
- name: Install Docker
  hosts: slurm_compute
  roles:
    - role: docker
      when: docker.install|bool == true
```

## Customizing Variables

### For Development/Testing

Create a `group_vars/all.yml` override file:

```yaml
---
# Override default versions for testing
slurm:
  version: "23.11.0"  # Test with older version

# Disable expensive features
install_docker: false
install_jupyterhub: false
```

### For Multi-Cluster Deployments

Create role-based group variable files:

```
group_vars/
├── all/
│   └── main.yml                 # Shared across all clusters
├── training/                    # Training cluster specific
│   └── main.yml
├── production/                  # Production cluster specific
│   └── main.yml
└── vault.yml                    # Shared secrets
```

Run with specific inventory:

```bash
ansible-playbook site.yaml -i inventory.yml -e "target_env=training"
```

## Best Practices

### 1. Use Vault for Secrets
Never commit passwords, tokens, or API keys to version control:

```bash
# WRONG - Don't do this
ldap_password: "MyPassword123"

# RIGHT - Use vault reference
ldap_password: "{{ vault_ldap_password }}"
```

### 2. Keep Variables Organized
Group related variables logically:

```yaml
# Good organization
slurm:
  version: "25.11.0"
  ports:
    ctld: 6817
    slurmd: 6818
  database:
    name: "slurm_db"
    user: "slurm"

# Avoid scattered variables
slurm_version: "25.11.0"
slurm_ctld_port: 6817
slurm_db_name: "slurm_db"
```

### 3. Document Non-Obvious Values
Add comments for complex or non-standard values:

```yaml
slurm:
  # Using older version for compatibility with legacy jobs
  version: "23.02.2"

  # Port numbers must match firewall rules in security groups
  dbd_port: "7031"
```

### 4. Use Environment Variables for Sensitive Data
For automated deployments, use environment variables:

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_password
ansible-playbook site.yaml -i inventory.yml
```

### 5. Version Control
Include `all/main.yml` in version control, but exclude:

```bash
# In .gitignore
group_vars/vault.yml
group_vars/**/vault.yml
.vault_password
```

## Troubleshooting Variable Issues

### Variables Not Being Applied

```bash
# Check variable values with debug
ansible localhost -m debug -a "var=slurm"

# View effective variables for a host
ansible-inventory -i inventory.yml --host <hostname> | jq .

# Verify playbook sees variables (dry run with verbose)
ansible-playbook site.yaml -i inventory.yml --check -vvv
```

### Vault-Related Issues

```bash
# Verify vault file is valid
ansible-vault view group_vars/vault.yml

# Fix vault password if locked
ansible-vault rekey group_vars/vault.yml

# Test vault variables
ansible localhost -i inventory.yml -m debug -a "var=vault_ldap_password" --ask-vault-pass
```

### Variable Precedence Conflicts

If a variable is set in multiple places:

1. Check role defaults: `roles/*/defaults/main.yml`
2. Check role variables: `roles/*/vars/main.yml`
3. Check group_vars: `group_vars/*/`
4. Check inventory: `inventory.yml`
5. Check command-line: `-e "var=value"`

Use `ansible-playbook ... -vvv` to see which file is being used.

## Advanced: Dynamic Inventory

For very large deployments, consider dynamic inventory:

```bash
# Generate inventory from cloud provider
ansible-inventory -i ./ec2.py --list | jq '.'

# Combine with static groups
ansible-inventory -i inventory.yml -i ec2.py --list
```

## Related Documentation

- Parent directory: See `/ansible/README.md` for deployment guide
- Roles: Each role has its own README in `roles/*/README.md`
- Terraform: See Terraform templates for how variables are generated
- Ansible: [Ansible Variables Documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html)
- Vault: [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
