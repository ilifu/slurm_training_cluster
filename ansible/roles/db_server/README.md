# Database Server Role

This role configures MariaDB database server for SLURM accounting (slurmdbd), providing persistent storage for job accounting, user accounts, and cluster resource tracking.

## Description

The database server hosts the SLURM accounting database using MariaDB. It stores job history, user accounts, resource utilization, and provides data for reporting and billing. The slurmdbd daemon connects the SLURM controller to this database for comprehensive accounting and resource tracking.

## Requirements

- Ubuntu 22.04 (Jammy Jellyfish)
- Sufficient storage for accounting data
- Network connectivity from SLURM controller
- MariaDB server packages

## Role Variables

### Required Variables
- `database_host` - Hostname of the database server
- `slurm_db_password` - Password for SLURM database user
- `db_name` - SLURM database name (default: slurmdb)

### Optional Variables
- `slurm_username` - SLURM system user (default: slurm)
- `slurm_group_name` - SLURM system group (default: slurm)

## Features

### Database Services
- **MariaDB Server** - Relational database for SLURM accounting
- **slurmdbd Daemon** - SLURM database daemon for accounting interface
- **Database Security** - Proper user permissions and access control
- **Data Persistence** - Reliable storage for historical job data

### Accounting Integration
- **Job Tracking** - Complete job lifecycle recording
- **Resource Accounting** - CPU hours, memory usage, and resource allocation
- **User Statistics** - Per-user resource consumption tracking
- **Cluster Metrics** - Overall cluster utilization and performance

### Database Management
- **Schema Setup** - SLURM database schema installation
- **User Management** - Database users and permissions
- **Backup Support** - Database backup and recovery capabilities
- **Performance Tuning** - Optimized configuration for SLURM workloads

## Dependencies

- **slurm_common** - Base SLURM configuration
- **base** - System base configuration

## Example Playbook

```yaml
- hosts: database_server
  become: yes
  roles:
    - role: db_server
      vars:
        database_host: "database.training.ilifu.ac.za"
        slurm_db_password: "{{ vault_slurm_db_password }}"
        db_name: "slurmdb"
```

## Database Schema

The SLURM database contains tables for:
- **Jobs** - Job submission, execution, and completion records
- **Users** - User account information and associations
- **Accounts** - Account hierarchies and limits
- **Clusters** - Cluster configuration and resources
- **Associations** - User-account-cluster relationships
- **Resources** - Node and partition resource definitions

## Service Integration

The slurmdbd daemon:
- **Controller Interface** - Receives accounting data from slurmctld
- **Database Writes** - Stores job and resource information
- **Query Processing** - Responds to accounting queries from SLURM commands
- **Data Validation** - Ensures data integrity and consistency

## Troubleshooting

### Common Issues
- **Connection Errors** - Check MariaDB service and network connectivity
- **Permission Denied** - Verify SLURM database user permissions
- **Disk Space** - Monitor storage usage for growing accounting database

### Useful Commands
```bash
# Check MariaDB status
sudo systemctl status mariadb

# Check slurmdbd status
sudo systemctl status slurmdbd

# Access SLURM database
mysql -u slurm -p slurmdb

# Monitor database logs
sudo journalctl -u mariadb -f
sudo journalctl -u slurmdbd -f
```

### Database Maintenance
```bash
# Check database size
sudo du -sh /var/lib/mysql/

# Backup database
mysqldump -u slurm -p slurmdb > slurmdb_backup.sql

# View SLURM accounting data
sacct --allusers --format=JobID,JobName,User,State,ExitCode,Submit,Start,End,Elapsed
```

## Performance Monitoring

Monitor database performance:
- **Connection Count** - Active database connections
- **Query Performance** - Slow query log analysis
- **Storage Growth** - Database size trends
- **Resource Usage** - CPU and memory utilization

## Tags

- `database` - Database-specific configuration
- `slurm` - SLURM accounting integration
- `mariadb` - MariaDB server setup
- `build` - Tasks run during image building

## Author Information

Part of the ILIFU CBIO SLURM Training Cluster deployment system.
