# [WIP]

## What is this?
This is a series of packer, terraform and ansible recipes/playbooks that will aid in creating a slurm cluster suitable
for training events. It is recommended that you create a standalone clone of this repository for each training cluster
you create – primarily because the terraform state file is stored locally and you don't want to accidentally overwrite
it.

The default setup will create a cluster with the following configuration:
* 1 login node (head node), 2×cores, ~8GiB RAM
* 1 slurm controller node, 2×cores, ~8GiB RAM  
* 1 database node, 2×cores, ~8GiB RAM
* 1 ldap node, 1×core, ~4GiB RAM
* 6 compute nodes, 240GiB RAM each (`ilifu-G-240G` flavor)
* /users cephfs directory ~50GiB
* /software cephfs directory ~20GiB
* /data cephfs directory
* Software installed includes slurm, singularity and openmpi

## How do I use it?
First you will need to download and install some pre-requisites including
[Packer and Terraform](https://www.packer.io/downloads). You will also need ansible and the OpenStack CLI client
running -- the recommended way is using `uv` (modern Python package manager):
```console
$ uv sync
```

### Get your OpenStack RC File
Sign into the OpenStack Dashboard, make sure you're working the correct project via the top menu bar, and then
download your [OpenStack RC File](https://dashboard2.ilifu.ac.za/project/api_access/). Once you have sourced this
file (`. your-project-openrc.sh`) you may move on to creating the base image.

### Setup your variables
First, generate the variables template:
```console
$ ./create_variables_auto_hcl_template.sh
```
Then use the `variables.auto.hcl.template` file to create a `variables.auto.hcl` file. This file will be used by both
packer and terraform when creating the cluster. The template file contains all the variables you can set and the
variable names are self-explanatory. The only variables you must set are those with `"<unknown>"` as the value.
Giving a little more information about these:

* `floating_ip_network_id = "<unknown>"`  _# the floating IP network ID, used when building the images_
* `ldap_password = "<unknown>"` _# the admin password for ldap, used by ansible when configuring ldap_
* `network_ids = "<unknown>"` _# An existing network, used when building images_
* `security_groups_ids = "<unknown>"` _# an existing security group, should allow incoming SSH, used when building images_
* `slurm_db_password = "<unknown>"` _# The slurmdb password, used by ansible when configuring the database_
* `ssh_key_location = "<unknown>"` _# The location of the public ssh key to use, used by ansible_
* `ssh_public_key = "<unknown>"` _# The public ssh key itself, used by terraform when deploying nodes_

Other noteworthy variables are:
* `build_flavor = "ilifu-B"` _# Flavour of machine used when building. Higher-core falvours might mean slighty fast build time_
* `ceph_net_name = "Ceph-net"` _# Name of the Ceph Network_
* `ceph_subnet_name = "Ceph-subnet"` _# Name of the Ceph Sub-network_
* `cidr_prefix = "192.168.20.0"` _# Network CIDR to use_
* `cidr_suffix = "24"` _# Network CIDR mask to use_
* `cluster_name = "training"` _# Name to give the training cluster_
* `controller_flavor = "ilifu-B"`
* `controller_host = "controller"` _# Name of the node where slurmctld will run_
* `database_flavor = "ilifu-B"`
* `database_host = "database"` _# Name of the node where the database and slurmdbd will run_
* `db_name = "slurmdb"` _# Name of the slurm database_
* `floating_ip_pool_name = "Ext_Floating_IP"`
* `image_name_prefix = "training-"` _# A prefix used on image names_
* `image_name_suffix = "-dev"` _# A suffix used on image names_
* `ldap_dns_domain_name = "training.ilifu.ac.za"` _# Name of the domain inside ldap_
* `ldap_flavor = "ilifu-A"`
* `ldap_host = "ldap"` _# Name of the host where ldap is running_
* `ldap_organisation_name = "training"`
* `login_flavor = "ilifu-B"`
* `login_host = "login"` _# Name of the login node_
* `password_login_enabled = false` _# Enable/disable SSH password authentication (default: false)_
* `slurm_group_name = "slurm"` _# The unix user that slurm runs as_
* `slurm_username = "slurm"` _# The unix group for slurm_
* `slurm_worker_count = "6"` _# Number of slurm workers to create_
* `slurm_worker_flavor = "ilifu-G-240G"` _# Large compute nodes with 240GiB RAM_
* `slurm_worker_node_name_prefix = "compute"` _# Worker nodes' prefix_
* `source_image_name = "20250728-jammy"` _# The starter image name (Ubuntu 22.04 jammy)_
* `node_name_suffix = ""` _# Optional suffix for node names (e.g., "-sep2025")_

#### Initialise Packer
Run `packer init .` to initialise packer. This will download the necessary plugins.

#### Build the images
Once you have set the variables you can build the images. This can simply be done with the `./build.sh` script. This
will create all the necessary images and initialise terraform.

The build script now uses `uv run openstack` commands for better dependency management.

#### Initialise Terraform
Run `terraform init` to initialise terraform. This will download the necessary plugins.

#### Deploy the nodes
Running `terraform apply` will deploy the nodes. **Deployment Order**: The system deploys nodes sequentially to optimize resource allocation:
1. Compute nodes first (to claim large `ilifu-G-240G` instances)
2. LDAP and Database nodes  
3. Controller node
4. Login node

This will take a while as the nodes are created. Occasionally this fails and simply rerunning will resume and hopefully fix any problems encountered (although one should pay attention to error messages). Terraform also creates an `inventory.ini`, and some variables in `ansible/group_vars/(all|slurm)/terraform.yml` so that ansible can then be run to configure the nodes.

#### Configure the nodes
Change to the `ansible` directory and run `ansible-playbook -i ../inventory.ini site.yml`. This will configure the
nodes and make your cluster usable.

#### Logging in and setting up the cluster
Find the IP address of your login node. You can check in the `inventory.ini` or run `uv run openstack server list` and
find the public IP address associated with your login node. Connect there as the `ubuntu` user using the ssh key
you specified in the `variables.auto.hcl` file.

#### Initializing SLURM accounts
After deployment, initialize the SLURM accounting system by running:
```bash
sudo /usr/local/bin/init_slurm_accounts
```
This script will:
- Create the default `training` account in SLURM
- Set up the `ubuntu` user with SLURM admin privileges
- Configure the accounting database

#### Creating user accounts
The cluster provides comprehensive user management through the `add_user.py` script located in `~/bin/`:

**Single user creation:**
```bash
# Create a regular user with SSH key
./add_user.py --make-changes -un johndoe -n John -sn Doe --ssh-public-key "ssh-rsa AAAAB3..."

# Create a user with random generated password
./add_user.py --make-changes -un johndoe -n John -sn Doe --password RANDOM

# Create an admin user with passwordless sudo and SLURM admin privileges
./add_user.py --make-changes -un admin1 -n Admin -sn User --password RANDOM --admin
```

**Bulk user creation:**
```bash
# Create 10 users (user01, user02, ..., user10) with random passwords
./add_user.py --make-changes --user_count 10

# Dry run to see what users would be created
./add_user.py --user_count 10
```

**Features:**
- **LDAP Integration**: Users are automatically added to the LDAP directory
- **SLURM Integration**: Users are automatically added to SLURM with the `training` account
- **Smart Numbering**: Bulk creation automatically detects existing user## accounts and continues numbering
- **Dictionary Passwords**: Random passwords use 5 English words for memorability
- **Admin Users**: Can grant passwordless sudo and SLURM admin privileges with `--admin` flag
- **Home Directory Creation**: Home directories are automatically created on first login in `/users`

#### Managing existing users
To add admin privileges to an existing user:
```bash
# Add to passwordless sudo group
sudo usermod -a -G admin username

# Grant SLURM admin privileges  
sacctmgr modify user where name=username set adminlevel=Admin
```

#### SSH Access Configuration
The cluster supports both key-based and password-based SSH authentication. Password authentication can be enabled/disabled via the `password_login_enabled` variable in `variables.auto.hcl`.


