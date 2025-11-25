# JupyterLab Role

This role installs JupyterLab on compute nodes, enabling users to launch interactive Jupyter notebook and lab environments directly on compute resources via SLURM job submission.

## Description

The jupyterlab role provides independent JupyterLab environments on each compute node:
- Installs system dependencies and Python virtual environment support
- Creates dedicated jupyter system user and group
- Builds isolated Python virtual environment at `/opt/jupyterlab/venv`
- Installs JupyterLab, JupyterHub, batchspawner, and data science packages
- Configures JupyterLab with Jupyter configuration files
- Sets up log directories with proper permissions
- Allows direct user access to Jupyter on compute nodes

This differs from the jupyterhub role (which runs on login node) by providing compute-node-local Jupyter instances that users can launch directly.

## Requirements

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ansible 2.10 or higher
- Root or sudo access on compute nodes
- Python 3.10+ (from common role)
- Virtual environment support via python3-venv
- Build tools (gcc, make) for compiling Python packages
- Network access to PyPI for package downloads
- Disk space: ~2GB in `/opt/jupyterlab` for virtual environment

## Role Variables

### Required Variables

No variables are strictly required. All have defaults defined in `defaults/main.yml`.

### Configuration Variables

All variables are defined in `defaults/main.yml` under the `jupyterlab` dictionary:

```yaml
jupyterlab:
  install: false                    # Set to true to enable installation
  version: "4.5.0"                 # JupyterLab version
  jupyter_user: "jupyter"          # System user for Jupyter
  jupyter_group: "jupyter"         # System group for Jupyter
```

### Path Variables

The role uses these path variables:

```yaml
jupyterlab_python_venv: "/opt/jupyterlab/venv"   # Python virtual environment
jupyterlab_config_dir: "/etc/jupyterlab"         # Configuration directory
jupyterlab_data_dir: "/var/lib/jupyterlab"       # Data directory
```

### Optional: Customize Installation

To override defaults, pass variables in the playbook:

```yaml
- role: jupyterlab
  vars:
    jupyterlab:
      install: true
      version: "4.4.0"           # Use different version
      jupyter_user: "jup_user"   # Custom system user
      jupyter_group: "jup_group" # Custom system group
    jupyterlab_python_venv: "/custom/path/venv"
    jupyterlab_config_dir: "/custom/etc/jupyterlab"
```

## Features

### System Setup

1. **System User & Group**
   - Creates system user `jupyter` (UID assigned by system)
   - Creates system group `jupyter` (GID assigned by system)
   - Home directory at `/var/lib/jupyterhub` (shared with jupyterhub)
   - Login shell: `/sbin/nologin` (system user, no direct login)

2. **Directory Structure**
   - `/opt/jupyterlab/venv` - Isolated Python virtual environment
   - `/etc/jupyterlab` - Configuration directory
   - `/var/lib/jupyterlab` - Data and working directory
   - `/var/log/jupyterlab` - Log directory

### Dependencies Installed

**System Packages:**
- `python3-venv` - Python virtual environment support
- `python3-dev` - Python development headers for compiling packages
- `build-essential` - GCC and build tools
- `git` - Git version control (for development packages)

**Python Packages (in venv):**
- `jupyterlab==4.5.0` (or specified version) - JupyterLab interface
- `jupyterhub==5.4.2` - JupyterHub hub for managing multiple instances
- `notebook>=6.1` - Jupyter notebook format support
- `batchspawner` - Spawn Jupyter kernels via batch job system (SLURM)
- `jupyterlab_server` - Server components for JupyterLab
- `ipykernel` - IPython kernel for notebooks

### Configuration

The role deploys `jupyter_lab_config.py` template to `/etc/jupyterlab/` for JupyterLab-specific settings.

### Permissions

All directories and files are owned by the `jupyter` user/group:
- `/opt/jupyterlab/venv` - 0755 (owner-executable)
- `/etc/jupyterlab` - 0755 (owner-readable)
- `/var/lib/jupyterlab` - 0755 (owner-accessible)
- `/var/log/jupyterlab` - 0755 (owner-writable)

## Installation Process

The role performs these steps in order:

### Phase 1: System Dependencies

```bash
# Update apt cache
apt update

# Install build dependencies
apt install python3-venv python3-dev build-essential git
```

### Phase 2: Jupyter User & Group

```bash
# Create system group
groupadd -r jupyter

# Create system user
useradd -r -g jupyter -s /sbin/nologin -d /var/lib/jupyterhub jupyter
```

### Phase 3: Directory Structure

```bash
# Create directories
mkdir -p /opt/jupyterlab/venv
mkdir -p /etc/jupyterlab
mkdir -p /var/lib/jupyterlab
mkdir -p /var/log/jupyterlab

# Set ownership and permissions
chown jupyter:jupyter /opt/jupyterlab/venv /etc/jupyterlab /var/lib/jupyterlab /var/log/jupyterlab
chmod 755 /opt/jupyterlab/venv /etc/jupyterlab /var/lib/jupyterlab /var/log/jupyterlab
```

### Phase 4: Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv /opt/jupyterlab/venv

# Upgrade pip
/opt/jupyterlab/venv/bin/pip install --upgrade pip
```

### Phase 5: Python Packages

```bash
# Install JupyterLab and dependencies in virtual environment
/opt/jupyterlab/venv/bin/pip install \
  jupyterhub==5.4.2 \
  jupyterlab==4.5.0 \
  batchspawner \
  notebook>=6.1 \
  jupyterlab_server \
  ipykernel
```

### Phase 6: Configuration

```bash
# Deploy JupyterLab configuration template
cp jupyter_lab_config.py.j2 /etc/jupyterlab/jupyter_lab_config.py
chown jupyter:jupyter /etc/jupyterlab/jupyter_lab_config.py
chmod 644 /etc/jupyterlab/jupyter_lab_config.py
```

## Dependencies

- **base** - Base OS installation (prerequisite)
- **common** - System packages including python3-dev (prerequisite)
- **slurm_common** - SLURM installation (optional, but needed for batchspawner to work)
- **slurm_worker** - Compute node SLURM daemon (on compute nodes)

This role should run on compute nodes after slurm_common.

## Deployment Order

Typical deployment order for compute nodes:

1. **base** - OS base configuration
2. **common** - System packages including Python
3. **slurm_common** - SLURM software stack
4. **ceph** - Mount CephFS (for shared home directories)
5. **slurm_worker** - Compute node SLURM daemon
6. **jupyterlab** - This role (JupyterLab on compute nodes)

## Example Playbook

To use this role as part of site.yaml:

```yaml
- name: Install JupyterLab on compute nodes
  hosts: slurm_compute                 # Only on compute nodes
  tags: [jupyterlab]
  roles:
    - jupyterlab                       # Installs if jupyterlab.install == true
```

To enable installation, set the variable in group_vars or inventory:

```yaml
# In group_vars/all/main.yml
jupyterlab:
  install: true
  version: "4.5.0"
```

Or run with command-line variable:

```bash
# Install JupyterLab on compute nodes
ansible-playbook site.yaml -i inventory.yml -t jupyterlab -e "jupyterlab.install=true"

# Or on specific nodes
ansible-playbook site.yaml -i inventory.yml -t jupyterlab -l "compute01" -e "jupyterlab.install=true"
```

## User Access

Once installed, users can access JupyterLab via:

1. **Direct SSH + Port Forwarding**
   ```bash
   # User connects to compute node and starts Jupyter
   ssh user@compute01
   /opt/jupyterlab/venv/bin/jupyter lab --ip=0.0.0.0 --port=8888

   # On local machine, forward port
   ssh -L 8888:compute01:8888 user@compute01

   # Access in browser: http://localhost:8888
   ```

2. **Via SLURM Job Submission (with batchspawner)**
   ```bash
   # User submits job that starts Jupyter
   sbatch --wrap="/opt/jupyterlab/venv/bin/jupyter lab --ip=0.0.0.0 --port=8888" \
          --partition=training --cpus-per-task=2 --mem=4G
   ```

3. **Via JupyterHub (if installed on login node)**
   - JupyterHub on login node can use batchspawner to launch Jupyter on compute nodes
   - Users access through login node's JupyterHub interface

## Verification

After this role completes, verify the installation:

```bash
# Check virtual environment exists
ls -la /opt/jupyterlab/venv/

# Verify Jupyter is installed
/opt/jupyterlab/venv/bin/jupyter --version
/opt/jupyterlab/venv/bin/jupyterlab --version

# Check configuration directory
ls -la /etc/jupyterlab/

# Verify data directory
ls -la /var/lib/jupyterlab/

# Check jupyter user exists
getent passwd jupyter

# Check jupyter group exists
getent group jupyter

# Verify log directory
ls -ld /var/log/jupyterlab

# Test launching Jupyter (on compute node)
/opt/jupyterlab/venv/bin/jupyter lab --help

# Check batchspawner installation
/opt/jupyterlab/venv/bin/python -c "import batchspawner; print(batchspawner.__version__)"
```

## Troubleshooting

### Virtual Environment Creation Fails

If virtual environment creation fails:

```bash
# Verify python3-venv is installed
dpkg -l | grep python3-venv

# Check available space
df -h /opt

# Try creating venv manually
python3 -m venv /tmp/test_venv

# Check Python version
python3 --version
```

### Package Installation Fails

If pip package installation fails:

```bash
# Check network connectivity
ping pypi.python.org

# Try installing in system Python (for debugging)
pip3 install jupyterlab

# Check pip cache
/opt/jupyterlab/venv/bin/pip cache info

# Try upgrading setuptools
/opt/jupyterlab/venv/bin/pip install --upgrade setuptools
```

### Jupyter User Not Created

If jupyter user doesn't exist:

```bash
# Verify user was created
id jupyter

# Create manually if needed
sudo useradd -r -g jupyter -s /sbin/nologin -d /var/lib/jupyterhub jupyter
```

### Configuration File Not Deployed

If JupyterLab config file is missing:

```bash
# Check if template exists
ls -la roles/jupyterlab/templates/jupyter_lab_config.py.j2

# Verify config directory
ls -la /etc/jupyterlab/

# Deploy manually
sudo cp roles/jupyterlab/templates/jupyter_lab_config.py.j2 \
        /etc/jupyterlab/jupyter_lab_config.py
sudo chown jupyter:jupyter /etc/jupyterlab/jupyter_lab_config.py
```

### JupyterLab Won't Start

If Jupyter fails to launch:

```bash
# Test from command line
/opt/jupyterlab/venv/bin/jupyter lab --version

# Start with verbose output
/opt/jupyterlab/venv/bin/jupyter lab --debug

# Check configuration syntax
/opt/jupyterlab/venv/bin/jupyter lab --generate-config

# View logs
tail -f /var/log/jupyterlab/
```

### Batchspawner Not Working

If jobs don't spawn via batchspawner:

```bash
# Verify batchspawner is installed
/opt/jupyterlab/venv/bin/pip show batchspawner

# Check SLURM is available
which sbatch squeue

# Test SLURM command manually
sbatch --version

# Verify user can submit jobs
sbatch --wrap="sleep 10" --partition=training

# Check batchspawner configuration in jupyter_lab_config.py
grep -i "batchspawner\|spawner" /etc/jupyterlab/jupyter_lab_config.py
```

## Configuration

### Customize JupyterLab Version

To install different version:

```yaml
jupyterlab:
  install: true
  version: "4.4.0"  # Use older version
```

Then re-run the role.

### Install Additional Python Packages

To install additional packages in the JupyterLab virtual environment:

```bash
# As root
/opt/jupyterlab/venv/bin/pip install numpy scipy matplotlib pandas scikit-learn
```

Or add to the role's pip task before applying.

### Enable SLURM Job Submission

To use batchspawner for SLURM job submission:

1. Ensure SLURM is installed (`slurm_common` role)
2. Configure batchspawner in `jupyter_lab_config.py`
3. Users can then launch notebooks via SLURM jobs

### Multi-User Environment

If running on shared compute node:

```bash
# Each user has their own configuration
~/.jupyter/jupyter_lab_config.py

# Virtual environment is shared
/opt/jupyterlab/venv (shared by all users)
```

## Security Considerations

1. **System User** - `jupyter` is a system user with `/sbin/nologin` shell
   - Cannot be used for interactive login
   - Runs only JupyterLab processes

2. **Virtual Environment Isolation** - Dependencies isolated in `/opt/jupyterlab/venv`
   - Won't conflict with system Python
   - Easy to remove by deleting directory

3. **Access Control** - Users must have valid accounts on compute nodes
   - Standard UNIX access controls apply
   - SSH keys or LDAP authentication recommended

4. **Network Security** - JupyterLab exposes kernel on open port
   - Use firewall rules to restrict access
   - Or require SSH port forwarding

5. **Data Protection** - Notebooks can access all user-readable files
   - No additional sandboxing
   - User permissions are enforced by OS

## Related Roles

- **common** - Installs python3-venv and build-essential
- **slurm_common** - Provides SLURM for batchspawner
- **slurm_worker** - Runs slurmd on compute nodes
- **ceph** - Mounts user home directories
- **jupyterhub** - Provides hub on login node (optional companion)

## Tags

- `jupyterlab` - Run entire role (all tasks)
- `build` - Run only package installation (apt packages)
- `config` - Run only configuration deployment

## Performance Notes

- **Installation Time** - 3-8 minutes (depends on network and CPU)
- **Virtual Environment Size** - ~800MB-1.2GB
- **Startup Time** - 5-15 seconds for JupyterLab to become responsive
- **Memory Usage** - ~300-500MB per JupyterLab instance
- **CPU Usage** - Low (~1-2% idle, varies with notebook operations)

## Differences from JupyterHub Role

| Aspect | JupyterLab (Compute Nodes) | JupyterHub (Login Node) |
|--------|--------------------------|------------------------|
| **Location** | Each compute node | Single login node |
| **Use Case** | Direct Jupyter access | Central hub for multi-user |
| **Access Method** | SSH + port forward | Web browser via hub |
| **Job Submission** | Manual or batchspawner | JupyterHub spawner |
| **Sharing** | Per-compute-node instances | Shared hub instance |
| **Configuration** | Simple config file | Complex with spawners/auth |

## Common Patterns

### Pattern: Direct User Access

Users with SSH access can launch Jupyter directly:

```bash
# User on compute01
/opt/jupyterlab/venv/bin/jupyter lab --ip=127.0.0.1 --port=8888

# Locally, forward port
ssh -L 8888:127.0.0.1:8888 user@compute01
```

### Pattern: Long-Running Jobs with Notebooks

Submit long-running jobs with Jupyter:

```bash
sbatch << 'EOF'
#!/bin/bash
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --job-name=jupyter_job

# Get the compute node
HOST=$(hostname)
PORT=8888

# Start Jupyter
/opt/jupyterlab/venv/bin/jupyter lab \
  --ip=0.0.0.0 \
  --port=$PORT \
  --no-browser \
  --log-level=INFO

EOF
```

### Pattern: Custom Package Installation

Install additional packages for all users:

```bash
# Install packages system-wide in venv
/opt/jupyterlab/venv/bin/pip install tensorflow pytorch

# Or users install locally
pip install --user custom_package
```

## References

- [JupyterLab Documentation](https://jupyterlab.readthedocs.io/)
- [JupyterHub Documentation](https://jupyterhub.readthedocs.io/)
- [Batchspawner Documentation](https://github.com/jupyterhub/batchspawner)
- [Jupyter Configuration](https://jupyter.readthedocs.io/en/latest/projects/jupyter-directories.html)
- [IPython Kernel](https://ipython.readthedocs.io/)

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
