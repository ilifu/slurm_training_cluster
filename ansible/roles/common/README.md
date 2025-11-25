# Common Role

This role installs essential packages and performs base system configuration on all cluster nodes (SLURM controller, login nodes, and compute nodes). It provides the foundation for all subsequent software installations and cluster services.

## Description

The common role prepares all nodes with:
- **Build and Development Tools** - Essential compilers and build utilities (build-essential, cmake, autoconf, make, llvm)
- **Development Libraries** - Required for compiling HPC software stacks
- **System Utilities** - Network, security, and administrative tools
- **HPC Libraries** - Numerical computation and data processing libraries (HDF5, NetCDF, GSL)
- **Authentication & Security** - LDAP/SSSD integration for centralized user management
- **Container Runtime Support** - Libraries for Singularity/CephFS integration
- **System Daemons** - Time synchronization (NTP), file security (fail2ban)

The role installs 92 packages total and performs user/group configuration.

## Requirements

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ansible 2.10 or higher
- Root or sudo access on target nodes
- Internet connectivity for apt package downloads
- Disk space: ~2GB for package installations

## Role Variables

No variables are required for this role. It installs fixed packages with no configuration options.

### Optional Commented Tasks

The role includes several commented-out tasks that may be enabled if needed:

- `extra_interfaces.yaml` - Network interface configuration (currently disabled)
- DHCP reconfiguration - For CephFS network interfaces (currently disabled)
- `iptables-persistent` - Firewall rule persistence (currently disabled)

## Package Categories

### Build and Development Tools (10 packages)
- `autoconf` - GNU Autoconf for configure scripts
- `build-essential` - GCC compiler, make, and related tools
- `cmake` - Cross-platform build system
- `llvm` - LLVM compiler infrastructure
- `make` - GNU Make build automation
- `pkg-config` - Helper tool for compile flags and libs
- `tcl-dev` - Tcl development files
- `tk-dev` - Tk development files
- `wget` - Command-line file downloader
- `git` - Distributed version control

### System Libraries and Development Headers (40+ packages)
**Compression/Archive:**
- `libbz2-dev`, `libreadline-dev`, `libsqlite3-dev`, `libxml2-dev`, `libxmlsec1-dev`
- `xz-utils`, `zlib1g-dev`, `unzip`, `zip`

**Graphics and Rendering:**
- `libcairo2-dev`, `libpng-dev`, `libtiff-dev`, `libxt-dev`, `xorg-dev`, `x11-common`, `xauth`

**Cryptography and Security:**
- `gnutls-bin`, `libcrypto++-dev`, `libcurl4-openssl-dev`, `libssl-dev`

**Data Processing:**
- `libdb-dev`, `libhdf5-dev`, `libnetcdf-dev`, `netcdf-bin`

**Hardware and Topology:**
- `libnuma-dev`, `libnuma1`, `libhwloc-dev`, `hwloc`, `numactl`

**Runtime and System:**
- `libelf-dev`, `libffi-dev`, `libjson-c-dev`, `liblzma-dev`, `libncurses5-dev`, `libpam0g-dev`, `libpcre2-dev`, `libperl-dev`, `libglib2.0-dev`

### Scientific and Numerical Libraries (3 packages)
- `gfortran` - GNU Fortran compiler
- `libgsl-dev` - GNU Scientific Library
- `python3-psutil` - Python system monitoring

### SLURM, Munge, and HPC Integration (6 packages)
- `munge` - Authentication daemon for SLURM
- `libmunge-dev` - Munge development library
- `libmariadb-dev` - MariaDB client library (SLURM database)
- `ldap-utils` - LDAP utilities for user management
- `libnss-ldapd` - NSS LDAP integration
- `libpam-sss` - PAM SSSD integration

### LDAP and User Authentication (4 packages)
- `sssd` - System Security Services Daemon
- `sssd-ldap` - SSSD LDAP provider
- `libnss-sss` - NSS integration with SSSD
- `ldap-utils` - LDAP command-line tools

### CephFS Support (3 packages)
- `ceph-common` - CephFS client utilities
- `libcephfs2` - CephFS C library
- `cgroup-lite`, `cgroup-tools`, `cgroupfs-mount` - cgroup support for containers

### Python Development (3 packages)
- `python3-dev` - Python 3 development headers
- `python3-coloredlogs` - Colored Python logging (utility)
- `virtualenv` - Python virtual environment tool

### Network and Remote Access (3 packages)
- `curl` - Command-line URL transfer tool
- `libssh2-1` - SSH library
- `sshfs` - SSH filesystem mount tool

### Security and Monitoring (2 packages)
- `fail2ban` - Intrusion prevention software
- `ssl-cert` - SSL certificate generation utility

### System Utilities (4 packages)
- `nano` - Text editor
- `zsh` - Z shell
- `ntp` - Network Time Protocol daemon
- `parallel` - GNU parallel command runner

### Additional Configuration (2 packages)
- `autofs` - Automatic filesystem mounting
- `dhcpcd5` - DHCP client
- `debootstrap` - Debian system bootstrap tool

## Features

### Package Installation
1. **Safe Upgrade** - Safely upgrades existing packages without removing installed packages
2. **Full Installation** - Installs 92 packages in single apt call with retry logic (3 retries, 15-second delay)
3. **Cache Update** - Updates apt cache before installation
4. **Cleanup** - Removes `unattended-upgrades` package (interferes with cluster operations)
5. **Autoremove** - Removes unnecessary dependencies after installation

### System Configuration
1. **Admin Group** - Creates system `admin` group with GID 110
2. **Ubuntu User** - Adds `ubuntu` user to admin group for sudo access

### Conditional Tasks
- Network interface configuration (disabled by default)
- DHCP reconfiguration (disabled by default)
- Firewall persistence (disabled by default)

## Dependencies

This role is applied before all other cluster configuration roles:
- **base** - OS installation (must run first)
- **common** - This role (must run second)
- All subsequent roles depend on this (slurm_common, ldap_*, ceph, etc.)

## Deployment Order

This role is part of the standard deployment sequence:

1. **base** - OS base configuration
2. **common** - This role (required by all subsequent roles)
3. **slurm_common** - SLURM software stack (depends on this role)
4. **ldap_client** - LDAP configuration (depends on ldap-utils from this role)
5. **ceph** - CephFS mounts (depends on ceph-common from this role)
6. **slurm_controller/slurm_worker** - SLURM daemons
7. Optional: docker, jupyterhub, jupyterlab, caddy

## Installation Process

The role performs these steps in order:

### Phase 1: Apt Maintenance
```bash
# Safe upgrade of existing packages
apt upgrade safe

# Update package cache
apt update
```

### Phase 2: Package Installation
- Installs 92 packages (see Package Categories above)
- Retries 3 times if installation fails (15-second delay between retries)
- Uses `state: latest` to ensure current versions

### Phase 3: Cleanup
```bash
# Remove unattended-upgrades (conflicts with cluster management)
apt remove unattended-upgrades

# Remove orphaned dependencies
apt autoremove
```

### Phase 4: System Configuration
- Creates admin group (GID 110)
- Adds ubuntu user to admin group for passwordless sudo

## Example Playbook

To use this role as part of site.yaml:

```yaml
- name: Common installation
  hosts: slurm                    # Applied to all SLURM hosts
  tags: [common]
  roles:
    - common
```

To run this role explicitly:

```bash
# Install common packages
ansible-playbook site.yaml -i inventory.yml -t common
```

## Verification

After this role completes, verify the installation:

```bash
# Check critical packages are installed
dpkg -l | grep -E "build-essential|cmake|munge|ldap-utils|ceph-common"

# Verify ubuntu user is in admin group
id ubuntu

# Check admin group exists with correct GID
getent group admin

# Verify LDAP libraries are available
dpkg -l | grep -E "libnss|libpam-sss|sssd"

# Check CephFS support is installed
dpkg -l | grep ceph

# Verify development headers are present
ls -d /usr/include/openssl /usr/include/curl /usr/include/hdf5 2>/dev/null
```

## Troubleshooting

### Package Installation Fails

If package installation fails even with retries:

```bash
# Check apt cache
sudo apt update

# Check for broken dependencies
sudo apt check

# Fix broken dependencies
sudo apt --fix-broken install

# Try installation manually
sudo apt install build-essential cmake munge ldap-utils
```

### Missing Development Headers

If a role fails to compile due to missing headers:

```bash
# Verify the package was installed
dpkg -l | grep <package-name>

# Check if headers are present
ls /usr/include/<library-name> 2>/dev/null

# Reinstall the package with development headers
sudo apt install --reinstall lib<name>-dev
```

### LDAP/SSSD Issues

If LDAP authentication fails after this role:

```bash
# Check SSSD is installed
dpkg -l | grep sssd

# Check NSS LDAP library
dpkg -l | grep libnss-sss

# Verify PAM SSSD integration
grep sssd /etc/pam.d/common-*
```

### CephFS Mount Problems

If CephFS mounts fail after this role:

```bash
# Check CephFS client is installed
dpkg -l | grep ceph-common

# Verify cgroup support
dpkg -l | grep cgroup

# Check CephFS library
dpkg -l | grep libcephfs
```

## Configuration

This role has no configuration variables. All packages are hardcoded based on the cluster's requirements.

### Optional: Enable Commented Tasks

To enable network interface configuration:

1. Uncomment the "extra_interfaces.yaml" task in tasks/tasks.yaml
2. Uncomment the "Ensure all the IPs are up" task
3. Verify extra_interfaces.yaml configuration
4. Re-run the role

## Security Considerations

1. **Unattended Upgrades** - Removed intentionally; cluster software versions must be controlled for reproducibility
2. **Fail2ban** - Installed for intrusion prevention; configure via `/etc/fail2ban/jail.conf`
3. **LDAP/SSSD** - Configured for centralized authentication; see ldap_client role for setup
4. **Build Tools** - Installed for software compilation; restrict access to build machines
5. **Development Headers** - Provide access to system libraries; keep updated with security patches

## Related Roles

- **base** - Prerequisite OS installation
- **slurm_common** - Depends on this role; builds SLURM with packages from here
- **ldap_client** - Depends on ldap-utils and SSSD from this role
- **ceph** - Depends on ceph-common from this role
- All other roles depend indirectly on this role through slurm_common

## Tags

- `common` - Run entire role (package installation + config)
- `build` - Run package installation and cleanup (tag used on all apt operations)

## Performance Notes

- **Installation Time**: 5-15 minutes (depending on network speed and mirror availability)
- **Disk Space**: ~2GB for package installations
- **Network**: Requires continuous internet access to apt mirrors
- **Retries**: Automatically retries failed apt operations up to 3 times

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.

## References

- [Ubuntu 22.04 Package Management](https://ubuntu.com/server/docs/package-management)
- [Ansible apt Module Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
- [Ansible user and group Module Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html)
