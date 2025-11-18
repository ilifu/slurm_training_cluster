JupyterHub with SlurmSpawner
=============================

Installs and configures JupyterHub on the login node with SlurmSpawner
for launching notebook sessions as SLURM batch jobs. This enables users
to interact with a notebook interface while their compute work runs on
the actual compute nodes via SLURM resource management.

Features
--------

- JupyterHub with JupyterLab interface
- SlurmSpawner for job-based notebook environments
- PAM authentication via SSSD/LDAP
- Systemd service management
- Configurable SLURM spawner settings (partition, memory, CPUs, time limit)
- Automatic notebook home directory creation

Requirements
------------

- Ubuntu 22.04 or compatible Linux distribution
- SLURM installed and operational (slurm_headnode, slurm_controller, slurm_compute roles)
- LDAP/SSSD authentication configured (ldap_client role)
- Python 3.8+ for virtual environment
- Internet access for package downloads

Role Variables
--------------

### Main Configuration (from `jupyterhub` dictionary)

- `jupyterhub.install` (bool, default: false) - Whether to install JupyterHub
- `jupyterhub.version` (string, default: "5.4.2") - JupyterHub version
- `jupyterhub.admin_users` (list, default: ["ubuntu"]) - Admin usernames
- `jupyterhub.jupyter_user` (string, default: "jupyter") - Service user name
- `jupyterhub.jupyter_group` (string, default: "jupyter") - Service group name

### Authenticator Configuration

- `jupyterhub.authenticator` (string, default: "pam") - Authenticator type
- Uses PAM which delegates to SSSD/LDAP for user authentication
- Supports LDAP users created with add_user.py script

### SlurmSpawner Configuration

- `jupyterhub.spawner_type` (string, default: "slurm") - Spawner implementation
- `jupyterhub.spawner_config.partition` (string, default: "debug") - SLURM partition
- `jupyterhub.spawner_config.memory` (string, default: "4G") - Memory per job
- `jupyterhub.spawner_config.cpus` (int, default: 2) - CPUs per job
- `jupyterhub.spawner_config.time_limit` (string, default: "01:00:00") - Max runtime
- `jupyterhub.spawner_config.prologue` (string) - Optional prologue script
- `jupyterhub.spawner_config.epilogue` (string) - Optional epilogue script

### Service Configuration

- `jupyterhub.service.ip` (string, default: "127.0.0.1") - Listening IP
- `jupyterhub.service.port` (int, default: 8000) - Listening port
- `jupyterhub.service.allow_root` (bool, default: false) - Allow running as root
- `jupyterhub.notebook_dir` (string, default: "/home/{username}") - Notebook directory

### Installation Paths (from `jupyterhub_*` variables)

- `jupyterhub_python_venv` (string, default: "/opt/jupyterhub/venv") - Virtual env
- `jupyterhub_config_dir` (string, default: "/etc/jupyterhub") - Config directory
- `jupyterhub_data_dir` (string, default: "/var/lib/jupyterhub") - Data directory

Dependencies
------------

Required roles (must be configured first):
- `slurm_headnode` - SLURM login node with slurmctld/slurmdbd access
- `ldap_client` - LDAP/SSSD authentication for user login
- `slurm_common` - SLURM common configuration

Usage Example
-------------

In your `site.yaml`, add the JupyterHub play (already included):

```yaml
- name: JupyterHub installation
  hosts: slurm_headnode
  tags: [jupyterhub]
  roles:
    - role: jupyterhub
      when: jupyterhub.install|bool == true
```

Enable in Terraform variables:

```hcl
variable "install_jupyterhub" {
  type = bool
  default = true
}
```

Or set in inventory:

```yaml
jupyterhub:
  install: true
  version: "5.4.2"
  admin_users:
    - ubuntu
    - researcher1
  spawner_config:
    partition: "gpu"
    memory: "8G"
    cpus: 4
    time_limit: "06:00:00"
```

How It Works
------------

1. User accesses JupyterHub via Caddy reverse proxy (https://domain/jupyter)
2. User authenticates with LDAP credentials via PAM
3. JupyterHub creates user home directory if needed
4. User clicks "Start Server" button
5. SlurmSpawner submits SLURM batch job with specified resources
6. SLURM launches notebook kernel on compute node
7. Notebook appears in browser, ready for interaction
8. User's work runs on compute node with allocated resources
9. SLURM terminates job after time_limit or user stops server

Configuration Files
--------------------

- `/etc/jupyterhub/jupyterhub_config.py` - Main JupyterHub configuration
- `/etc/systemd/system/jupyterhub.service` - Systemd service file
- `/var/lib/jupyterhub/` - JupyterHub data directory (SQLite DB, etc.)

Service Management
-------------------

JupyterHub is managed via systemd:

```bash
# Check status
systemctl status jupyterhub

# View logs
journalctl -u jupyterhub -f

# Restart service
systemctl restart jupyterhub

# Start/stop manually
systemctl stop jupyterhub
systemctl start jupyterhub
```

Accessing JupyterHub
---------------------

With Caddy reverse proxy configured:
- URL: `https://training.ilifu.ac.za/jupyter`
- Or direct: `http://localhost:8000` (from login node)

Default admin user: `ubuntu` (from Terraform/inventory)

SLURM Partition Configuration
------------------------------

Ensure a partition exists for notebook jobs:

```bash
# View current partitions
sinfo

# Example partition in slurm.conf:
# PartitionName=debug Nodes=compute-[0-5] Default=YES MaxTime=01:00:00 State=UP
```

If no partition matches `spawner_config.partition`, jobs will fail.
Verify partition name in defaults or inventory.

Troubleshooting
---------------

### JupyterHub won't start
Check logs: `journalctl -u jupyterhub -e`

### Users can't log in
Verify LDAP users exist: `getent passwd username`

### Jobs won't spawn
Check SLURM: `sinfo` and `squeue`
Verify partition exists and is accessible
Check spawner settings match your SLURM configuration

### Notebooks won't connect
Check firewall: port 8000 must be accessible to Caddy
Check systemd service: `systemctl status jupyterhub`

License
-------

MIT-0

Author Information
-------------------

Part of SLURM Training Cluster Deployment Toolkit
Designed for training and education on HPC cluster administration