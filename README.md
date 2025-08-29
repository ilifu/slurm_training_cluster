# [WIP]

## What is this?
This is a series of packer, terraform and ansible recipes/playbooks that will aid in creating a slurm cluster suitable
for training events. It is recommended that you create a standalone clone of this repository for each training cluster
you create – primarily because the terraform state file is stored locally and you don't want to accidentally overwrite
it.

The default setup will create a cluster with the following configuration:
* 1 head node, 2×cores, ~8GiB RAM
* 1 slurm controller node, 2×cores, ~8GiB RAM
* 1 database node, 2×cores, ~8GiB RAM
* 1 ldap node, 1×core, ~4GiB RAM
* 3 compute nodes, 8×cores, ~64GiB RAM
* /users cephfs directory ~50GiB
* /software cephfs directory ~20GiB
* Software installed includes slurm, singularity and openmpi

## How do I use it?
First you will need to download and install some pre-requisites including
[Packer and Terraform](https://www.packer.io/downloads). You will also need ansible and the OpenStack CLI client
running -- the recommended way for this is either setting up a virtual environment and installing with `pip`, e.g.
```console
$ virtualenv -p python3 .venv
$ . .venv/bin/activate
$ pip install -r requirements.txt
```
or using `pipenv`, e.g.
```console
$ pipenv sync
$ pipenv shell
```
Note the current version requires python 3.10.
### Get your OpenStack RC File
Sign into the OpenStack Dashboard, make sure you're working the correct project via the top menu bar, and then
download your [OpenStack RC File](https://dashboard2.ilifu.ac.za/project/api_access/). Once you have sourced this
file (`. your-project-openrc.sh`) you may move on to creating the base image.

### Setup your variables
Use the `variables.auto.hcl.template` file to create a `variables.auto.hcl` file. This file will be used by both
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
* `slurm_group_name = "slurm"` _# The unix user that slurm runs as_
* `slurm_username = "slurm"` _# The unix group for slurm_
* `slurm_worker_count = "3"` _# Number of slurm workers to create_
* `slurm_worker_flavor = "ilifu-E"`
* `slurm_worker_node_name_prefix = "compute"` _# Worker nodes' prefix_
* `source_image_id = "0f3e66e2-49e0-4efa-af1d-fd5a2f79f5f6"` _# The starter image (currently a recent ubuntu 22.04 image)

#### Initialise Packer
Run `packer init .` to initialise packer. This will download the necessary plugins.

#### Build the images
Once you have set the variables you can build the images. This can simply be done with the `./build.sh` script. This
will create all the necessary images and initialise terraform.


#### Initialise Terraform
Run `terraform init` to initialise terraform. This will download the necessary plugins.

#### Deploy the nodes
Running `terraform apply` will deploy the nodes. This will take a while as the nodes are created. Occasionally this
fails and simply rerunning will resume and hopefully fix any problems encountered (although one should pay attention
error messages). Terraform also creates an `inventory.ini`, and some variables in
`ansible/group_vars/(all|slurm)/terraform.yml` so that ansible can then be run to configure the nodes.

#### Configure the nodes
Change to the `ansible` directory and run `ansible-playbook -i ../inventory.ini site.yml`. This will configure the
nodes and make your cluster usable.

#### Logging in and creating user accounts
Find the IP address of your login node. You can check in the `inventory.ini` or run `openstack server list` and
find the public IP address associated with your login node. Connect there as the `ubuntu` user using the ssh key
you specified in the `variables.auto.hcl` file. You can then create user accounts using the `add_user.py` script
which will add the users to the ldap server. When they login for the first time their home directories will
be automatically created on the `/users` cephfs directory.

#### Creating slurm accounts and users
As root (`sudo su `) on the login node you should first create a default accounting group. This is done with
`sacctmgr add account name=training description="Default training account"`. You can then create a user for `ubuntu` with:
`sacctmgr create user name=ubuntu DefaultAccount=training` and then give them admin privileges with:
`sacctmgr modify user where name=ubuntu set adminlevel=Admin`. You can then stop being root and perform slurm
admin commands as the `ubuntu` user. So for users who have had unix accounts added, they can have slurm
accounts added with `sacctmgr create user name=<username> DefaultAccount=training`.


