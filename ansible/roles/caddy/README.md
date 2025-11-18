Caddy Reverse Proxy
===================

Installs and configures Caddy as a reverse proxy server with hierarchical,
service-owned configuration files. Caddy is designed to be service-agnostic
and can route traffic to multiple backend services including JupyterHub,
RStudio, VSCode, and other web applications.

Architecture
------------

Caddy uses a hierarchical configuration structure where:
- **Main Caddyfile** (`/etc/caddy/Caddyfile`) - Contains only global ACME and
  logging settings, plus an import directive
- **Service configs** (`/etc/caddy/conf.d/*.conf`) - Each service (JupyterHub,
  RStudio, etc.) manages its own config file

```
/etc/caddy/
├── Caddyfile              (Main - global config + import directive)
└── conf.d/
    ├── jupyterhub.conf    (Deployed by jupyterhub role)
    ├── rstudio.conf       (Deployed by future rstudio role)
    └── vscode.conf        (Deployed by future vscode role)
```

This design provides:
- **Modularity**: Each service is self-contained
- **Scalability**: Add services without modifying Caddyfile
- **Clarity**: Service config location is predictable
- **Validation**: Configuration validated before reload
- **Separation of Concerns**: Service roles own their routing config

Requirements
------------

- Ubuntu 22.04 or compatible Linux distribution
- Root or sudo access for installation
- Internet access to download Caddy from official repository

Role Variables
--------------

### Main Configuration (from `caddy` dictionary)

- `caddy.install` (bool, default: false) - Whether to install Caddy
- `caddy.domain` (string, default: "training.ilifu.ac.za") - Primary domain
- `caddy.email` (string, default: "admin@training.ilifu.ac.za") - Email for Let's Encrypt
- `caddy.acme_provider` (string, default: "letsencrypt") - ACME certificate provider
- `caddy.port_http` (int, default: 80) - HTTP port
- `caddy.port_https` (int, default: 443) - HTTPS port
- `caddy.config_dir` (string, default: "/etc/caddy/conf.d") - Service config directory

Dependencies
------------

None. This role installs all required dependencies.

Usage Example
-------------

In your `site.yaml` (already configured):

```yaml
- name: Configure Caddy reverse proxy
  hosts: slurm_headnode
  tags: [caddy]
  roles:
    - role: caddy
      when: caddy.install|bool == true
```

Configuration Variables in Inventory
-------------------------------------

Set in your Ansible inventory or group_vars:

```yaml
caddy:
  install: true
  domain: "cluster.example.com"
  email: "admin@example.com"
  config_dir: "/etc/caddy/conf.d"
```

Or from Terraform variables (passed via inventory template):

```hcl
# variables.hcl
variable "domain_name" {
  type = string
  default = "training.ilifu.ac.za"
}
```

Automatic HTTPS with Let's Encrypt
-----------------------------------

Caddy automatically:
- Obtains certificates from Let's Encrypt
- Redirects HTTP to HTTPS
- Manages certificate renewal

For self-signed certificates or custom ACME providers,
modify the `acme_provider` variable.

Service Management
-------------------

Caddy is managed via systemd:

```bash
# Check status
systemctl status caddy

# View logs
journalctl -u caddy -f

# Validate configuration
caddy validate --config /etc/caddy/Caddyfile

# Reload configuration
systemctl reload caddy

# Restart service
systemctl restart caddy
```

Configuration Files
-------------------

- **Main Caddyfile**: `/etc/caddy/Caddyfile` - Generated from Caddyfile.j2
  - Contains only global options and import directive
  - Service configs are imported from /etc/caddy/conf.d/

- **Service configs**: `/etc/caddy/conf.d/*.conf` - Created by service roles
  - Each service creates its own .conf file
  - Example: JupyterHub creates jupyterhub.conf

Adding a New Service
---------------------

To add a new service (e.g., RStudio):

1. Create a new role:
   ```bash
   ansible-galaxy init rstudio
   ```

2. Create Caddy config template in `rstudio/templates/caddy_rstudio.conf.j2`:
   ```caddy
   {% if rstudio.install %}
   {{ caddy.domain }} {
     reverse_proxy /rstudio* localhost:8787 {
       header_up X-Forwarded-Proto {scheme}
       header_up X-Forwarded-Host {host}
     }
   }
   {% endif %}
   ```

3. Add task in `rstudio/tasks/main.yml`:
   ```yaml
   - name: Deploy RStudio Caddy configuration
     template:
       src: caddy_rstudio.conf.j2
       dest: "{{ caddy.config_dir }}/rstudio.conf"
       owner: root
       group: caddy
       mode: '0644'
     notify:
       - Validate Caddy configuration
       - Reload Caddy
     when: caddy.install|bool == true
   ```

4. Add to site.yaml and set `rstudio.install: true`

**That's it!** No changes needed to Caddy role or main Caddyfile.

Configuration Validation
------------------------

Before reloading Caddy, the configuration is validated using:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

If validation fails, the reload is skipped and an error is reported.
This prevents broken deployments from misconfigured service files.

Handlers
--------

The Caddy role provides handlers for service roles:

- `Validate Caddy configuration` - Validates main Caddyfile + all imports
- `Reload Caddy` - Reloads Caddy with validated configuration

Service roles notify these handlers when deploying config:
```yaml
notify:
  - Validate Caddy configuration
  - Reload Caddy
```

Troubleshooting
---------------

### Configuration validation fails
Check the error message for syntax issues in service config files:
```bash
caddy validate --config /etc/caddy/Caddyfile
```

### Service config not loading
Verify:
1. File is in `/etc/caddy/conf.d/` directory
2. File has `.conf` extension
3. File owner is root, group is caddy: `ls -la /etc/caddy/conf.d/`
4. File permissions allow caddy to read: `chmod 644`

### Changes not taking effect
Reload Caddy:
```bash
systemctl reload caddy
```

### HTTPS certificate not working
Check certificate status:
```bash
caddy-api/config
```

Or check Caddy logs:
```bash
journalctl -u caddy -f
```

License
-------

MIT-0

Author Information
-------------------

Part of SLURM Training Cluster Deployment Toolkit
Designed for training and education on HPC cluster administration
