# SLURM Worker Role

This role configures SLURM compute nodes (slurmd), which execute jobs scheduled by the SLURM controller.

## Description

SLURM worker nodes are the compute resources where jobs actually run. This role configures the slurmd daemon, sets up the compute environment, and ensures proper integration with the SLURM controller. Worker nodes register with the controller and accept jobs for execution.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- High-memory compute instances (240GiB RAM recommended)
- Network connectivity to SLURM controller
- SLURM common configuration already applied
- Scientific computing software stack

## Role Variables

### Required Variables
- `controller_host` - Hostname of the SLURM controller
- `slurm_cluster_name` - Name of the SLURM cluster

### Optional Variables
- `slurm_username` - SLURM system user (default: slurm)
- `slurm_group_name` - SLURM system group (default: slurm)
- `slurm_worker_flavor` - Instance flavor (default: ilifu-G-240G)

### Hardware Configuration
- **CPU Cores** - All available CPU cores reported to SLURM
- **Memory** - 240GiB RAM on ilifu-G-240G instances
- **Storage** - Local storage for temporary job data

## Features

### Compute Daemon
- **slurmd Service** - Worker daemon that executes jobs
- **Resource Reporting** - Reports CPU, memory, and storage to controller
- **Job Execution** - Manages job processes and resource allocation
- **Health Monitoring** - Node status reporting to controller

### Job Environment
- **User Isolation** - Proper job containment and resource limits
- **Environment Setup** - Module system and software access
- **Shared Storage** - Access to /users, /software, and /data filesystems
- **Scientific Software** - Pre-installed computational tools

### Resource Management
- **CPU Allocation** - Per-job CPU core assignment
- **Memory Control** - Memory limits and monitoring
- **Process Management** - Job lifecycle management
- **Cleanup** - Automatic cleanup after job completion

## Dependencies

- **slurm_common** - Base SLURM configuration and packages
- **software** - Scientific computing software stack
- **ceph** - Shared filesystem mounting
- **ldap_client** - User authentication
- **base** - System base configuration

## Example Playbook

```yaml
- hosts: slurm_workers
  become: yes
  roles:
    - role: slurm_worker
      vars:
        controller_host: "controller.training.ilifu.ac.za"
        slurm_cluster_name: "training"
```

## Node Registration

Worker nodes automatically register with the controller upon startup. The controller tracks:
- **Node Status** - UP, DOWN, IDLE, ALLOCATED
- **Resource Availability** - Free CPU cores and memory
- **Job Assignment** - Currently running jobs
- **Health Status** - Node responsiveness and errors

## Job Execution

When jobs are assigned to the node:
1. **Resource Allocation** - CPU cores and memory reserved
2. **User Environment** - Job runs as submitted user (via LDAP)
3. **Working Directory** - Job executes in user's home directory
4. **Software Access** - Modules and software available via /software
5. **Data Access** - Input/output via shared /data filesystem

## Troubleshooting

### Common Issues
- **Node Offline** - Check network connectivity to controller
- **Job Failures** - Verify user permissions and software availability
- **Resource Exhaustion** - Monitor CPU and memory usage

### Useful Commands
```bash
# Check worker daemon status
sudo systemctl status slurmd

# View node information from any node
sinfo -N

# Check node-specific details
scontrol show node $(hostname)

# Monitor worker logs
sudo journalctl -u slurmd -f

# Check resource usage
top
free -h
```

### Performance Monitoring
```bash
# View running jobs on this node
squeue -w $(hostname)

# Check job details
scontrol show job JOBID
```

## Tags

- `slurm` - SLURM-related configuration
- `worker` - Worker-specific tasks
- `build` - Tasks run during image building

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
