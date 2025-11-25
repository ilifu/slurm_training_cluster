# SLURM Common Role

This role installs and configures the complete SLURM software stack and supporting HPC libraries on all SLURM cluster nodes (controller, login, and compute nodes). It is the foundation for the entire cluster infrastructure.

## Description

The SLURM common role compiles and installs a comprehensive HPC software ecosystem including:
- **Go Language** - Required for Singularity compilation
- **Singularity/Apptainer** - Container runtime for HPC (compiles from source)
- **OpenUCX** - High-performance communication library
- **OpenPMIx** - Process management interface for HPC
- **SLURM** - Cluster resource manager and job scheduler (compiles from source with extensive options)
- **Open MPI** - Message passing library for parallel computing
- **Lmod** - Environment modules system for managing software

Additionally, the role:
- Installs 62 build and development packages required for compilation
- Creates SLURM system user and group
- Generates Munge authentication key
- Creates SLURM configuration files (slurm.conf, cgroup.conf, topology.conf, etc.)
- Configures Singularity bind paths for CephFS mounts
- Sets up environment variables for all users via /etc/profile.d/ scripts
- Creates symlinks for SLURM commands

## Requirements

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Minimum 2GB free disk space in /opt (for compiled software)
- Build tools and development libraries (installed by this role)
- At least 30 minutes for full compilation (depending on hardware)
- Tags: Use `--tags slurm_common` or `--tags build` to run compilation

## Role Variables

### Global Configuration Variables (from group_vars/all/main.yml)

#### Go Language Installation
```yaml
go:
  version: "1.25"                              # Go version to install
  url: "https://go.dev/dl/go1.25.4.linux-amd64.tar.gz"
  checksum: "sha256:..."                       # SHA256 checksum for verification
```

#### Singularity Container Runtime
```yaml
singularity:
  version: "4.3.4"                            # Singularity version to compile
  url: "https://github.com/sylabs/singularity/releases/download/v4.3.4/singularity-ce-4.3.4.tar.gz"
  checksum: "sha256:..."                       # SHA256 checksum for verification
```

#### High-Performance Communication Libraries

**UCX (Unified Communication X)** - Low-level communication layer:
```yaml
ucx:
  version: "1.19.0"                           # UCX version
  url: "https://github.com/openucx/ucx/releases/download/v1.19.0/ucx-1.19.0.tar.gz"
  checksum: "sha256:..."                       # SHA256 checksum
  dir: "/opt/ucx"                             # Installation directory
```

**OpenPMIx** - Process management interface for exascale computing:
```yaml
pmix:
  version: "5.0.9"                            # OpenPMIx version
  url: "https://github.com/openpmix/openpmix/releases/download/v5.0.9/pmix-5.0.9.tar.gz"
  checksum: "sha1:..."                         # SHA1 checksum
```

**Open MPI** - MPI implementation with PMIx and UCX support:
```yaml
mpi:
  version: "5.0.8"                            # Open MPI version
  url: "https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.8.tar.bz2"
  checksum: "sha256:..."                       # SHA256 checksum
```

#### SLURM Cluster Manager
```yaml
slurm:
  version: "25.11.0"                          # SLURM version to compile
  version_git: "25-11-0-1"                    # Git tag for source code
  db_name: "slurm_db"                         # Database name (created by db_server role)
  db_user: "slurm"                            # Database user
  dbd_port: "7031"                            # SLURM daemon broker port
  ctld_port: "6817"                           # SLURM controller port
  slurmd_port: "6818"                         # SLURM compute daemon port
  spool_dir: "/var/spool/slurmd"              # Job spool directory
  accounts:                                   # SLURM billing accounts
    training: "Basic account for training"    # Default account
```

#### Lmod Environment Modules
```yaml
lmod:
  version: "9.0.2"                            # Lmod version
  url: "https://github.com/TACC/Lmod/archive/refs/tags/9.0.2.tar.gz"
  checksum: "sha256:..."                       # SHA256 checksum
```

### SLURM Configuration Variables (from group_vars or templates)

These variables are used in generating SLURM configuration files:

```yaml
slurm_config:                                 # SLURM configuration object
  controller_host: "controller.example.com"  # SLURM controller hostname
  database_host: "database.example.com"      # MariaDB host for accounting
  cluster_name: "training"                   # Cluster name for sinfo display
  login_node: "login.example.com"            # Login node hostname
```

### CephFS Mount Configuration

The role configures Singularity to bind mount CephFS filesystems. Configure via:

```yaml
ceph_mounts:                                  # From Terraform/group_vars
  home:
    mount_point: "/users"
  data:
    mount_point: "/data"
  software:
    mount_point: "/software"
  scratch:
    mount_point: "/scratch"
```

## Features

### Software Compilation and Installation

1. **Go Language** - Extracted to /opt/go
   - Added to PATH via /etc/profile.d/golang.sh
   - GOPATH set to ~/go

2. **Singularity** - Compiled from source with:
   - Configurable HTTP proxy support
   - Cgroup v2 support
   - Seccomp support
   - Installed to /usr/local/bin/singularity

3. **Communication Libraries** (UCX, OpenPMIx, Open MPI)
   - Compiled in sequence with dependencies
   - UCX installed to /opt/ucx
   - OpenMPI installed to /opt/openmpi

4. **SLURM** - Compiled from source with options:
   - MariaDB support for accounting (slurmdbd)
   - Munge authentication
   - Lua 5.4 support for job steps
   - Singularity container integration
   - Installed to /opt/slurm

5. **Lmod** - Environment modules system installed

### System Configuration

- **Munge Authentication Key** (/etc/munge/munge.key)
  - Generated or copied from controller
  - Required for inter-node communication

- **SLURM System User** (slurm:slurm)
  - UID/GID 5000
  - Home directory /var/spool/slurm

- **SLURM Directories**
  ```
  /var/spool/slurmd           # Job spool
  /var/log/slurm              # SLURM logs
  /opt/slurm                  # Installation directory
  /opt/slurm/*/etc            # Configuration
  /opt/slurm/*/lib            # Libraries
  ```

- **Configuration Files**
  - /opt/slurm/*/etc/slurm.conf - Main SLURM configuration
  - /opt/slurm/*/etc/cgroup.conf - Cgroup configuration
  - /opt/slurm/*/etc/acct_gather.conf - Accounting configuration
  - /opt/slurm/*/etc/topology.conf - Node topology

- **Environment Setup** (via /etc/profile.d/)
  - golang.sh - Go environment
  - openmpi.sh - Open MPI paths
  - slurm.sh - SLURM paths
  - lmod.sh - Environment modules
  - singularity.sh - Singularity configuration
  - ucx.sh - UCX library paths

- **Singularity Bind Mounts**
  - Configured for CephFS mount points
  - Allows containers to access /users, /data, /software, /scratch

## Dependencies

- **base** - Base operating system installation
- **common** - Common packages and system configuration
- **db_server** - MariaDB database (required on controller for slurmdbd)

Note: slurm_common must be installed on ALL cluster nodes (controller, login, compute) before installing role-specific configurations.

## Deployment Order

This role must be deployed in a specific order:

1. **base** - OS updates and basic configuration
2. **common** - Development packages and tools
3. **slurm_common** - Compile and install SLURM stack (this role)
4. **db_server** - Database server (controller only)
5. **slurm_controller** - Controller daemon (controller only)
6. **slurm_worker** - Compute node daemon (compute nodes)

## Installation Process

The role performs these steps:

### Phase 1: Package Installation
- Installs 62 build and development packages
- Enables apt caching for retry resilience
- Installs with up to 3 retries (15 second delay)

### Phase 2: Go Language
- Downloads Go tarball
- Extracts to /opt/go
- Configures PATH and GOPATH

### Phase 3: Singularity Compilation
- Downloads Singularity source
- Configures with Go environment
- Compiles from source (~5-10 minutes)
- Installs to /usr/local/bin

### Phase 4: Communication Libraries
- **UCX** - Downloaded and compiled (~5-10 minutes)
- **OpenPMIx** - Downloaded and compiled (~5-10 minutes)
- **Open MPI** - Downloaded and compiled with PMIx/UCX (~10-15 minutes)

### Phase 5: SLURM Compilation
- Downloads SLURM source
- Configures with extensive options (see tasks.yaml)
- Compiles from source (~10-20 minutes depending on CPU cores)
- Installs to /opt/slurm
- Creates symlinks for commands

### Phase 6: Lmod Installation
- Downloads Lmod source
- Compiles and installs environment modules system

### Phase 7: Configuration
- Creates SLURM user and groups
- Generates Munge key
- Creates configuration files from Jinja2 templates
- Sets up environment variables
- Configures Singularity

## Example Playbook

To use this role as part of the site.yaml playbook:

```yaml
- name: Slurm common installation
  hosts: slurm                           # Applied to all SLURM hosts
  tags: [slurm_common]
  roles:
    - slurm_common
```

To run this role explicitly with tags:

```bash
# Install just SLURM common (include all dependencies)
ansible-playbook site.yaml -i inventory.yml -t slurm_common --ask-vault-pass

# Install specific components (Go, Singularity, etc.)
ansible-playbook site.yaml -i inventory.yml -t golang,singularity --ask-vault-pass
```

## Configuration

### Custom Versions

To use different software versions, update group_vars/all/main.yml:

```yaml
go:
  version: "1.24"  # Use older Go version
  url: "https://..."

slurm:
  version: "23.11.0"  # Use older SLURM version
  version_git: "23-11-0"
```

### SLURM Compilation Options

SLURM is compiled with these options (see tasks.yaml for full list):
- `--with-mysql_config` - MariaDB support
- `--with-munge` - Munge authentication
- `--with-lua` - Lua 5.4 support
- `--with-singularity` - Singularity integration
- `--enable-slurmctld` - Controller daemon
- And 20+ other options

To modify compilation options, edit tasks.yaml and update the SLURM configure command.

### Munge Key Management

- **First Run**: Key is generated on each node
- **Subsequent Runs**: Key from controller should be distributed to all nodes
  - Copy /etc/munge/munge.key from controller to compute nodes
  - Permissions: 400, owned by munge:munge

## Verification

After this role completes, verify the installation:

```bash
# Check Go
/opt/go/bin/go version

# Check Singularity
/usr/local/bin/singularity --version

# Check SLURM
/opt/slurm/*/bin/slurmctl --version

# Check libraries
ls -la /opt/{ucx,openmpi}/lib

# Check environment
source /etc/profile.d/slurm.sh
echo $SLURM_HOME
```

## Troubleshooting

### Compilation Failures

If compilation fails:

```bash
# Check logs
tail -50 /tmp/go_download.log
tail -50 /tmp/singularity_build.log
tail -50 /tmp/slurm_build.log

# Re-run role
ansible-playbook site.yaml -i inventory.yml -t slurm_common --ask-vault-pass

# Check disk space
df -h /opt
```

### Common Issues

1. **Out of Disk Space**
   - Check /opt has at least 2GB free
   - SLURM compilation can take 1+ GB

2. **Compilation Timeout**
   - Increase timeout in tasks.yaml
   - CPU-intensive tasks may take longer on small VMs

3. **Munge Key Issues**
   - All nodes must have same munge.key
   - Check permissions: `ls -l /etc/munge/munge.key`
   - Should be 400 owned by munge:munge

4. **Missing Dependencies**
   - Role installs 62 packages required for compilation
   - If building without this role's package installation, install manually

### Debug Mode

Run with verbose output:

```bash
ansible-playbook site.yaml -i inventory.yml -t slurm_common -vvv --ask-vault-pass
```

## Related Roles

- **slurm_controller** - Configure SLURM controller daemon (depends on this role)
- **slurm_worker** - Configure compute node daemon (depends on this role)
- **db_server** - Database for SLURM accounting
- **common** - Prerequisite packages and configuration

## Performance Notes

- **Compilation Time**: 45-90 minutes total (depends on CPU cores)
- **Disk Space**: ~2GB in /opt for compiled software
- **Memory**: At least 512MB free for compilation
- **Network**: Internet access required to download sources

## Security Considerations

1. **Munge Key** - Should be protected (400 permissions)
2. **SLURM User** - Has system access, run cluster services as this user
3. **Source Verification** - SHA256 checksums verify downloaded files
4. **Container Runtime** - Singularity runs unprivileged containers

## Tags

- `build` - Run compilation tasks (default on Packer builds)
- `slurm_common` - Run entire role
- `golang` - Install Go language only
- `singularity` - Install Singularity only
- `pmix` - Install OpenPMIx only
- `ucx` - Install UCX only
- `openmpi` - Install Open MPI only
- `slurm` - Install SLURM only
- `lmod` - Install Lmod only
- `apt` - Install apt packages

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.

## References

- [SLURM Documentation](https://slurm.schedmd.com/)
- [Singularity Documentation](https://docs.sylabs.io/)
- [Open MPI Documentation](https://www.open-mpi.org/)
- [Lmod Documentation](https://lmod.readthedocs.io/)
