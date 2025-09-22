# SLURM Controller Role

This role configures the SLURM controller node (slurmctld), which manages job scheduling, resource allocation, and cluster coordination.

## Description

The SLURM controller is the central management daemon for the cluster. It handles job submission, scheduling, resource allocation, and communicates with compute nodes and the accounting database. This role configures slurmctld with proper database integration and sets up the controller for cluster management.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- Functional MariaDB database server (slurmdbd)
- Network connectivity to database and compute nodes
- SLURM common configuration already applied

## Role Variables

### Required Variables
- `controller_host` - Hostname of the controller node
- `database_host` - Hostname of the database server
- `slurm_cluster_name` - Name of the SLURM cluster
- `slurm_db_password` - Password for SLURM database connection

### Optional Variables
- `slurm_username` - SLURM system user (default: slurm)
- `slurm_group_name` - SLURM system group (default: slurm)

## Features

### Controller Daemon
- **slurmctld Service** - Main SLURM controller daemon
- **Job Scheduling** - Manages job queue and resource allocation
- **Node Management** - Tracks compute node status and availability
- **Database Integration** - Connects to slurmdbd for accounting

### Configuration Management
- **slurm.conf** - Main SLURM configuration file
- **Resource Definition** - Defines partitions, nodes, and resources
- **Policy Configuration** - Job limits, priorities, and scheduling policies

### Service Management
- **Systemd Integration** - Proper service configuration and startup
- **Log Management** - Centralized logging configuration
- **Process Monitoring** - Health checks and automatic restart

## Dependencies

- **slurm_common** - Base SLURM configuration and packages
- **db_server** - Database server for accounting
- **base** - System base configuration

## Example Playbook

```yaml
- hosts: slurm_controller
  become: yes
  roles:
    - role: slurm_controller
      vars:
        controller_host: "controller.training.ilifu.ac.za"
        database_host: "database.training.ilifu.ac.za"
        slurm_cluster_name: "training"
        slurm_db_password: "{{ vault_slurm_db_password }}"
```

## Configuration

The controller manages cluster resources through slurm.conf, including:
- **Compute Nodes** - Node definitions with CPU, memory, and features
- **Partitions** - Logical groupings of nodes for job submission
- **Scheduling** - Job prioritization and resource allocation policies

## Troubleshooting

### Common Issues
- **Database Connection** - Verify slurmdbd is running and accessible
- **Node Communication** - Check network connectivity to compute nodes
- **Configuration Errors** - Validate slurm.conf syntax

### Useful Commands
```bash
# Check controller status
sudo systemctl status slurmctld

# View cluster information
sinfo

# Check node status
sinfo -N

# Monitor controller logs
sudo journalctl -u slurmctld -f
```

## Tags

- `slurm` - SLURM-related configuration
- `controller` - Controller-specific tasks
- `build` - Tasks run during image building

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
