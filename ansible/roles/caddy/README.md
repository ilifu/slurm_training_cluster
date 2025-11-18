Caddy
=====

Installs and configures Caddy as a reverse proxy server. Caddy is designed
to be service-agnostic and can route traffic to multiple backend services
including JupyterHub, RStudio, VSCode, and other web applications.

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

### Routing Configuration

Routes are defined in the Caddyfile template. By default, if JupyterHub is
installed, Caddy will reverse proxy traffic from `${domain}/jupyter*` to
`localhost:8000`.

Example route for future services:
```caddy
reverse_proxy /rstudio* localhost:8787
reverse_proxy /vscode* localhost:8443
```

Dependencies
------------

None. This role installs all required dependencies.

Usage Example
-------------

In your `site.yaml`, add the Caddy play:

```yaml
- name: Configure Caddy reverse proxy
  hosts: login_node
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

# Reload configuration
systemctl reload caddy

# Restart service
systemctl restart caddy
```

Configuration File
-------------------

The Caddyfile is generated from the `templates/Caddyfile.j2` template
and placed at `/etc/caddy/Caddyfile`.

License
-------

MIT-0

Author Information
-------------------

Part of SLURM Training Cluster Deployment Toolkit
Designed for training and education on HPC cluster administration