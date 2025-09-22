# CephFS Client Role

This role configures CephFS client mounting for shared storage access across the cluster, providing `/users`, `/software`, and `/data` filesystems.

## Description

CephFS provides distributed shared storage for the cluster. This role mounts CephFS filesystems that are shared across all nodes, enabling users to access their home directories, shared software, and data from any node in the cluster.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)  
- Network connectivity to CephFS cluster
- Proper CephFS credentials and configuration

## Role Variables

### Required Variables
- `ceph_net_name` - Ceph network name
- `ceph_subnet_name` - Ceph subnet name

## Features

### Shared Filesystems
- **`/users`** - User home directories (~50GiB)
- **`/software`** - Shared scientific software (~20GiB)  
- **`/data`** - Shared data storage
- **Automatic Mounting** - Persistent mounts via /etc/fstab

### Client Configuration
- **CephFS Kernel Module** - Native kernel client for performance
- **Authentication** - Secure access to CephFS cluster
- **Performance Tuning** - Optimized mount options

## Dependencies

- **base** - System base configuration

## Example Playbook

```yaml
- hosts: cluster_nodes
  become: yes
  roles:
    - role: ceph
      vars:
        ceph_net_name: "Ceph-net"
        ceph_subnet_name: "Ceph-subnet"
```

## Mount Points

The role creates these shared filesystems:
- **`/users`** - User home directories (auto-created on first login)
- **`/software`** - Scientific computing software and modules
- **`/data`** - Shared project and research data

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
