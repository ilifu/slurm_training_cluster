# Scientific Software Role

This role installs and configures scientific computing software and tools for the SLURM training cluster.

## Description

Installs essential scientific computing software including SLURM, Singularity, OpenMPI, and other tools needed for computational research and training. Software is installed in `/software` shared filesystem for cluster-wide access.

## Features

- **SLURM** - Workload manager and job scheduler
- **Singularity** - Container runtime for scientific applications  
- **OpenMPI** - Message Passing Interface for parallel computing
- **Scientific Libraries** - Common computational libraries and tools
- **Environment Modules** - Software environment management

## Dependencies

- **base** - System base configuration
- **ceph** - Shared `/software` filesystem

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
