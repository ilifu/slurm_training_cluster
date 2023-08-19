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
packer and terraform to create the cluster. The template file contains all the variables you can set and the
variable names are self-explanatory. The only variables you must set are those with 