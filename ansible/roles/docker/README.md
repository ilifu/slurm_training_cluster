Docker
======

Installs and configures Docker CE on compute nodes. Optionally grants Docker
access to specified users by adding them to the `docker` group.

Features
--------

- Docker CE installation from official repository
- Optional user Docker access via group membership
- Flexible user permission management through Ansible
- Idempotent configuration (safe to run multiple times)
- Fine-grained control via inventory variables

Requirements
------------

- Ubuntu 22.04 or compatible Linux distribution
- Root or sudo access for installation
- Internet access to download Docker packages

Role Variables
--------------

### Main Configuration (from `docker` dictionary)

- `docker.install` (bool, default: false) - Whether to install Docker
- `docker.user_docker` (bool, default: false) - Enable user Docker access

### User Permissions

- `docker_privileged_users` (list, default: []) - Users to add to docker group

Example Configuration
---------------------

In your inventory or `group_vars/slurm_compute.yml`:

```yaml
docker:
  install: true
  user_docker: true

docker_privileged_users:
  - researcher1
  - researcher2
  - ubuntu
```

Installation Only (No User Access)
-----------------------------------

To install Docker without granting user access:

```yaml
docker:
  install: true
  user_docker: false

docker_privileged_users: []
```

Dependencies
------------

None. This role installs all required dependencies.

How It Works
------------

### Phase 1: Installation
When `docker.install: true`:
1. Install Docker dependencies
2. Add Docker official repository
3. Install Docker CE packages
4. Start and enable Docker service

### Phase 2: User Permissions
When `docker.install: true` AND `docker.user_docker: true`:
1. Create docker group on system
2. Add specified users to docker group
3. Users can run docker without `sudo`

### User Access Workflow

1. User is created in LDAP via `add_user.py` (unchanged)
   - No modifications needed to user creation script
   - `add_user.py` remains focused on LDAP operations only

2. Docker role runs and adds user to docker group
   - Via Ansible's `user` module
   - Idempotent: safe to run multiple times

3. User logs into compute node via SSH
   - First login: group membership may not be active in existing sessions
   - Solution: User logs out and back in, or runs `exec newgrp docker`

4. User runs Docker commands directly:
   ```bash
   docker run -it ubuntu bash
   ```

Design Philosophy
-----------------

This role follows **Separation of Concerns:**

- `add_user.py` - Handles LDAP user creation only
  - Centralized, directory-focused
  - No changes needed

- `docker` role - Handles Docker installation and permissions
  - Node-level configuration
  - Ansible manages local system groups
  - Appropriate separation of responsibilities

This approach keeps systems decoupled and maintainable.

Idempotency
-----------

All tasks in this role are idempotent. You can safely run the Docker role
multiple times:

```bash
# Safe to run multiple times
ansible-playbook -i inventory.yml site.yml -t docker
```

Running again will:
- Verify packages are installed (no action if already present)
- Verify users are in docker group (no action if already members)
- Ensure service is running (restart only if not running)

Service Management
-------------------

Docker is managed via systemd:

```bash
# Check status
systemctl status docker

# View logs
journalctl -u docker -f

# Start/stop/restart
systemctl start docker
systemctl stop docker
systemctl restart docker
```

Adding/Removing Users
---------------------

### Adding Users

1. Update `docker_privileged_users` in inventory:
   ```yaml
   docker_privileged_users:
     - user1
     - user2
     - user3
   ```

2. Re-run the Docker role:
   ```bash
   ansible-playbook -i inventory.yml site.yml -t docker
   ```

3. User logs out and back in for changes to take effect

### Removing Users

Removing from `docker_privileged_users` will NOT automatically remove them
from the docker group. To remove user access:

```bash
sudo gpasswd -d username docker
```

Or create an Ansible task in a separate playbook:
```yaml
- name: Remove user from docker group
  user:
    name: username
    groups: docker
    state: absent
```

Security Considerations
-----------------------

**IMPORTANT:** Granting Docker access is a significant security decision.

Users in the `docker` group can:
- Run containers with full system access
- Mount host filesystems into containers
- Access host devices
- Effectively gain root-level privileges

**Best Practices:**
- Only add trusted users to `docker_privileged_users`
- Review and audit group membership regularly
- Consider resource limits for container workloads
- Use security scanning for container images
- Document who has Docker access and why

Troubleshooting
---------------

### Docker service won't start
Check logs:
```bash
journalctl -u docker -e
```

### Users can't run docker commands
Verify user is in docker group:
```bash
groups username
```

Should show `docker` in the output. If not:
1. Re-run Docker role
2. User logs out and back in

Alternatively, user can activate group immediately:
```bash
exec newgrp docker
```

### Docker command permission denied
If user still gets "permission denied":
1. Verify user exists on system: `getent passwd username`
2. Verify docker group exists: `getent group docker`
3. Verify group membership: `groups username`
4. Check file permissions: `ls -l /var/run/docker.sock`

### New packages available
To upgrade Docker to latest version:
```bash
ansible-playbook -i inventory.yml site.yml -t docker
apt update && apt upgrade docker-ce
```

Integration with Compute Nodes
-------------------------------

This role is designed for the `slurm_compute` group.

In `site.yaml`:
```yaml
- name: Docker installation on compute nodes
  hosts: slurm_compute
  tags: [docker]
  roles:
    - role: docker
      when: docker.install|bool == true
```

Deploy Docker to compute nodes:
```bash
ansible-playbook -i inventory.yml site.yml -t docker
```

License
-------

MIT-0

Author Information
-------------------

Part of SLURM Training Cluster Deployment Toolkit
Designed for training and education on HPC cluster administration