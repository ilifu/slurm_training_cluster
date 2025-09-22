# Base System Role

This role provides fundamental system configuration for all cluster nodes, including timezone setup, package updates, and basic system hardening.

## Description

The base role configures essential system settings that all cluster nodes require. It handles timezone configuration, system package updates, and provides a foundation for other roles to build upon.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- Internet connectivity for package updates

## Role Variables

### Required Variables
- `timezone` - System timezone (default: Africa/Johannesburg)

## Features

- **Timezone Configuration** - Sets system timezone and updates tzdata
- **Package Management** - Updates all system packages to latest versions
- **System Hardening** - Basic security configurations
- **Foundation Setup** - Prepares system for specialized roles

## Dependencies

None - this is a foundational role.

## Example Playbook

```yaml
- hosts: all
  become: yes
  roles:
    - role: base
      vars:
        timezone: "Africa/Johannesburg"
```

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
