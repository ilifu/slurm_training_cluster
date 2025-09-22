# Software Repository Role

This role clones and configures the ilifu/software repository for scientific computing software management in the SLURM training cluster.

## Description

This role clones the [ilifu/software](https://github.com/ilifu/software.git) repository to `/software/.software` (hidden directory) and configures it for use with the cluster's admin group structure. The repository contains Ansible playbooks and configurations for managing scientific software installations across the cluster.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- CephFS `/software` filesystem mounted and accessible
- Git package installed
- Internet connectivity for repository cloning

## Role Variables

No custom variables required - this role uses sensible defaults.

## Features

### Repository Management
- **Git Clone** - Clones ilifu/software repository to `/software/.software` (hidden directory)
- **Mount Dependency** - Waits for `/software` mount point to be available
- **Directory Permissions** - Sets ubuntu:admin ownership on `/software` with rwxrwxr-x permissions and setgid bit
- **Repository Ownership** - Sets ubuntu:admin ownership with 755 permissions on cloned repository
- **Configuration Update** - Updates admin_group setting from "ubuntu" to "admin"

### Configuration Changes
- **Admin Group Update** - Modifies `/software/.software/ansible/group_vars/all`
- **Backup Creation** - Creates backup of original configuration before modification
- **Safe Replacement** - Uses regex matching to safely update admin_group setting

### Error Handling
- **Mount Verification** - Ensures `/software` is accessible before proceeding
- **File Existence Checks** - Verifies configuration files exist before modification
- **Timeout Protection** - 5-minute timeout for mount point availability

## Dependencies

- **ceph** - Provides `/software` filesystem mount required for repository storage
- **common** - Provides admin group setup (ubuntu user added to admin group)

## Example Playbook

```yaml
- hosts: slurm_headnode, slurm_compute
  become: yes
  roles:
    - role: ceph        # Must run before software role

- hosts: slurm_compute[0]  # Only run on first compute node (shared CephFS)
  become: yes
  roles:
    - role: software
```

## Repository Structure

After successful execution, the following structure is created:

```
/software/.software/
├── ansible/
│   ├── group_vars/
│   │   └── all          # Contains admin_group: "admin" setting
│   └── ...              # Other Ansible configurations
└── ...                  # Scientific software management files
```

## Integration

The cloned repository integrates with the cluster by:
- **Admin Group Alignment** - Uses cluster's "admin" group instead of default "ubuntu"
- **Shared Access** - Available on all nodes with `/software` mount
- **Software Management** - Provides infrastructure for managing scientific software
- **Optimized Deployment** - Only runs on first compute node since `/software` is shared CephFS storage
- **Idempotent Operation** - Checks for existing repository to avoid unnecessary re-cloning
- **Proper Permissions** - Sets `/software` directory permissions to allow admin group read/write access
- **Group Inheritance** - Uses setgid bit so new files/directories inherit admin group ownership

## Troubleshooting

### Common Issues
- **Mount Not Available** - Ensure CephFS is properly configured and mounted
- **Permission Errors** - Verify proper filesystem permissions on `/software`
- **Network Issues** - Check internet connectivity for git clone operations

### Useful Commands
```bash
# Check if software repository is cloned
ls -la /software/.software/

# Verify admin_group configuration
grep admin_group /software/.software/ansible/group_vars/all

# Check mount status
mount | grep /software

# Verify /software directory permissions (should show setgid bit)
ls -ld /software
```

## Tags

- `software` - Software repository management tasks

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
