# Hosts Role

This role configures hostname resolution and system hostnames on all cluster nodes. It populates `/etc/hosts` with cluster node IP addresses and sets each node's hostname to match the inventory hostname.

## Description

The hosts role provides essential network name resolution configuration for the SLURM cluster:
- Updates `/etc/hosts` file with all cluster nodes and their private IP addresses
- Sets system hostname to match inventory hostname
- Enables nodes to communicate by hostname rather than IP address
- Provides DNS-like resolution without requiring external DNS infrastructure

This enables services like SLURM controller, compute nodes, and databases to locate each other by hostname on the internal cluster network.

## Requirements

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ansible 2.10 or higher
- Root or sudo access to modify `/etc/hosts` and system hostname
- Inventory with `private_ip` host variables for all nodes
- All nodes must be known to Ansible (in inventory)

## Role Variables

### Required Variables

This role requires host-level variables from the Ansible inventory:

#### `private_ip` - Private Network IP Address

Each host must have a `private_ip` variable defined in inventory.

```yaml
# In inventory.yml or host_vars/
all:
  hosts:
    controller:
      private_ip: 10.0.0.10
    login:
      private_ip: 10.0.0.20
    compute01:
      private_ip: 10.0.0.30
    compute02:
      private_ip: 10.0.0.31
```

### Dynamic Variables

The role uses these Ansible built-in variables:

- `groups['all']` - List of all hosts in inventory
- `hostvars[item].private_ip` - Private IP of each host
- `inventory_hostname` - Current host's inventory name

## Features

### `/etc/hosts` Configuration

- Iterates through all hosts in `groups['all']`
- Adds or updates entries with format: `<private_ip>  <hostname>`
- Uses `lineinfile` module for idempotent updates
- Matches existing entries by hostname to avoid duplicates
- Preserves other `/etc/hosts` entries (localhost, IPv6, etc.)

### System Hostname Setting

- Sets each node's hostname to `inventory_hostname`
- Uses `hostname` module to apply changes immediately
- Updates system hostname persistently
- Affects all hostname-based services and communications

### Example `/etc/hosts` Result

After this role runs, `/etc/hosts` contains entries like:

```
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

# Added by hosts role:
10.0.0.10       controller
10.0.0.20       login
10.0.0.30       compute01
10.0.0.31       compute02
10.0.0.32       compute05
10.0.0.50       database
10.0.0.51       ldap
```

## Dependencies

- **base** - Base OS installation (prerequisite)
- Terraform/Inventory - Must provide `private_ip` variables for all hosts

This role should run early, before services that depend on hostname resolution.

## Deployment Order

This role is typically deployed in this sequence:

1. **base** - OS base configuration
2. **hosts** - This role (set up hostname resolution)
3. All subsequent roles can rely on hostname resolution

## Installation Process

The role performs these steps in order:

### Phase 1: Update /etc/hosts for Each Host

For each host in the inventory:

```bash
# Example for controller
lineinfile /etc/hosts
  Match pattern: ".*\\s{{ item }}"  (any existing entry for this hostname)
  Replace with: "10.0.0.10    controller"

# Example for compute01
lineinfile /etc/hosts
  Match pattern: ".*\\scompute01"
  Replace with: "10.0.0.30    compute01"
```

This modifies `/etc/hosts` to include all cluster nodes with their private IPs.

### Phase 2: Set System Hostname

For each node running this role:

```bash
# Set hostname
hostnamectl set-hostname controller
hostnamectl set-hostname compute01

# Verify
hostname
```

The `/etc/hostname` file is updated and hostname service is configured.

## Example Playbook

To use this role as part of site.yaml:

```yaml
- name: Configure hostnames and hosts file
  hosts: all                    # Run on all cluster nodes
  tags: [hosts]
  roles:
    - hosts
```

To run this role explicitly:

```bash
# Configure hostnames on all nodes
ansible-playbook site.yaml -i inventory.yml -t hosts

# Or on specific hosts
ansible-playbook site.yaml -i inventory.yml -t hosts -l "slurm_compute"
```

## Inventory Configuration

Ensure your inventory has `private_ip` defined for all hosts:

```yaml
# inventory.yml
all:
  children:
    slurm:
      children:
        slurm_headnode:
          hosts:
            login:
              private_ip: 10.0.0.20
        slurm_controller:
          hosts:
            controller:
              private_ip: 10.0.0.10
        slurm_compute:
          hosts:
            compute01:
              private_ip: 10.0.0.30
            compute02:
              private_ip: 10.0.0.31
            compute03:
              private_ip: 10.0.0.32
            compute04:
              private_ip: 10.0.0.33
            compute05:
              private_ip: 10.0.0.34
            compute06:
              private_ip: 10.0.0.35
    ldap:
      hosts:
        ldap:
          private_ip: 10.0.0.51
    slurm_database:
      hosts:
        database:
          private_ip: 10.0.0.50
```

Or with host_vars files:

```yaml
# host_vars/controller.yml
private_ip: 10.0.0.10
cluster_name: training
region: region1

# host_vars/compute01.yml
private_ip: 10.0.0.30
compute_id: 1
memory_gb: 240
```

## Verification

After this role completes, verify hostname configuration:

```bash
# Check hostname on each node
hostname

# Verify /etc/hosts entries
cat /etc/hosts | grep -E "10\.|^[^#].*compute|^[^#].*controller"

# Test hostname resolution
ping controller
ping compute01
ping login

# Test from another node
ssh compute01 -c "ping controller"

# Check hostname is persistent
sudo hostnamectl status

# Verify all cluster nodes are resolvable
for node in $(ansible all -i inventory.yml --list-hosts); do
  ping -c 1 $node && echo "$node OK" || echo "$node FAILED"
done
```

## Troubleshooting

### Hostname Not Changing

If system hostname doesn't update:

```bash
# Check current hostname
hostname

# Check hostname file
cat /etc/hostname

# Set hostname manually
sudo hostnamectl set-hostname controller

# Verify with hostnamectl
sudo hostnamectl status
```

### /etc/hosts Entries Not Added

If /etc/hosts is missing cluster nodes:

```bash
# Check current /etc/hosts
cat /etc/hosts

# Check that private_ip is defined in inventory
ansible controller -i inventory.yml -m debug -a "var=private_ip"

# If variable is missing, add to inventory and re-run role
```

### Hostname Resolution Not Working

If `ping controller` fails:

```bash
# Check /etc/hosts has all entries
grep controller /etc/hosts

# Test with getent (uses /etc/hosts + DNS)
getent hosts controller

# Check hostname case sensitivity
ping Controller    # May fail if /etc/hosts has "controller"

# Test with explicit IP
ping 10.0.0.10

# If network connectivity fails, check:
ip addr show       # Check IP address
ip route show      # Check routing
```

### DNS Conflict

If external DNS is interfering:

```bash
# Check nsswitch configuration
cat /etc/nsswitch.conf

# Should prioritize /etc/hosts:
# hosts:  files dns

# Edit if needed:
sudo sed -i 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf

# Restart nscd if running
sudo systemctl restart nscd
```

### Hostname Changes Reverted After Reboot

This shouldn't happen, but if hostname reverts:

```bash
# Check /etc/hostname file exists and has correct content
cat /etc/hostname

# Check cloud-init isn't overriding (on cloud systems)
sudo cat /etc/cloud/cloud.cfg | grep hostname

# If using cloud-init, disable hostname management:
sudo sed -i 's/^\(.*preserve_hostname\).*/\1: true/' /etc/cloud/cloud.cfg
```

## Configuration

### Custom IP Assignments

To customize private IP assignments, edit inventory:

```yaml
all:
  hosts:
    controller:
      private_ip: 192.168.1.10    # Different subnet
    login:
      private_ip: 192.168.1.20
    compute01:
      private_ip: 192.168.1.30
```

Then re-run the role to update /etc/hosts.

### Dynamic Hostname Prefixes

To use custom hostname prefixes (generated by Terraform):

```yaml
# In inventory
all:
  hosts:
    "{{ cluster_name }}-controller":
      private_ip: 10.0.0.10
    "{{ cluster_name }}-compute01":
      private_ip: 10.0.0.30
```

The role will use the actual inventory hostname automatically.

### Handling DNS Fallback

To ensure hostname resolution falls back to DNS if needed:

```bash
# Check nsswitch.conf
cat /etc/nsswitch.conf | grep "^hosts:"

# Should show:
# hosts: files dns

# If DNS is installed and configured, this provides fallback
```

## Security Considerations

1. **Network Isolation** - `/etc/hosts` works only on local network
   - Provides DNS-like functionality without exposing to internet
   - Suitable for internal cluster networks

2. **IP Spoofing Prevention** - Verify inventory IP addresses are correct
   - Misconfigured IPs can cause routing issues
   - Use internal network IPs only

3. **Hostname Consistency** - All nodes must have consistent hostnames
   - SLURM uses hostnames for node identification
   - Hostname mismatches can cause job submission failures

4. **Access Control** - Modifying /etc/hosts requires root access
   - This role requires sudo/root privileges
   - Restrict who can run this role

## Related Roles

- **base** - Prerequisite OS installation
- **slurm_controller** - Depends on hostname resolution
- **slurm_worker** - Uses hostnames for node registration
- **ldap_client** - May use hostnames for LDAP server lookups
- All cluster services that communicate by hostname

## Tags

- `hosts` - Run entire role (update /etc/hosts and set hostname)

## Performance Notes

- **Execution Time** - Usually < 1 second per node
- **Total Time** - 10-30 seconds for all nodes (depends on cluster size)
- **idempotent** - Safe to run multiple times without changes

## Common Patterns

### Pattern: Multi-Cluster Deployments

For multiple independent clusters:

```yaml
# inventory.yml with multiple clusters
training:
  children:
    training_compute:
      hosts:
        training-compute01:
          private_ip: 10.0.0.30
        training-compute02:
          private_ip: 10.0.0.31

production:
  children:
    production_compute:
      hosts:
        prod-compute01:
          private_ip: 192.168.0.30
        prod-compute02:
          private_ip: 192.168.0.31

# Each cluster gets its own /etc/hosts entries
```

### Pattern: Verifying Hostname Resolution

Before running cluster-dependent roles:

```bash
# Verify all nodes resolve by hostname
ansible all -i inventory.yml -m shell -a "hostname && ping -c 1 controller" -b
```

### Pattern: Custom Hostname Format

To use fully qualified domain names (FQDNs):

```yaml
# In inventory
all:
  hosts:
    controller.training.local:
      private_ip: 10.0.0.10
    compute01.training.local:
      private_ip: 10.0.0.30
```

The role will use the full inventory hostname.

## Debugging

### Enable Verbose Output

```bash
# See what lineinfile is doing
ansible-playbook site.yaml -i inventory.yml -t hosts -vvv | grep -A5 -B5 "lineinfile\|hostname"
```

### Check Host Variables

```bash
# See what private_ip values are being used
ansible all -i inventory.yml -m debug -a "var=hostvars[inventory_hostname]['private_ip']" -e "ansible_become=false"
```

### Test Hostname Before Role

```bash
# Verify hostnames resolve before role runs
ansible all -i inventory.yml -m shell -a "getent hosts {{ inventory_hostname }}" -b
```

## References

- [Ansible hostname Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/hostname_module.html)
- [Ansible lineinfile Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html)
- [Linux /etc/hosts File](https://man7.org/linux/man-pages/man5/hosts.5.html)
- [Hostname Resolution](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html)
- [hostnamectl Command](https://man7.org/linux/man-pages/man1/hostnamectl.1.html)

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
