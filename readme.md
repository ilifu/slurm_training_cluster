# [WIP]

## What is this?

This is a series of packer, terraform and ansible recipes/playbooks that will aid in creating a slurm cluster suitable for training events.
## How do I use it?
First you will need to download and install some pre-requisites including [Packer and Terraform](https://www.packer.io/downloads). You will also need ansible and the OpenStack CLI client running -- the recommended way for this is either setting up a virtual environment and installing with `pip`, e.g.
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

### Get your OpenStack RC File
Sign into the OpenStack Dashboard, make sure you're working the correct project via the top menu bar, and then download your [OpenStack RC File](https://dashboard2.ilifu.ac.za/project/api_access/). Once you have sourced this file (`. your-project-openrc.sh`) you may move on to creating the base image.


### Create a project directory
Create a project directory with a `.project` suffix (mainly so that it can be ignored by git), say `CBIO_16s_2021.project`. Change to this directory and the rest of the setup will be executed from there.

### Create your base image
Create your `packer_variables.json` file using the template file found in `templates/packer_variables.json`), i.e. `cp ../templates/packer_variables.json ./`. Edit this file so that you have the appropriate IDs in place. Note if you installed the CLI client, then the commands you might use are:
`openstack flavor list`, `openstack image list`, `openstack network list` and `openstack security group list`. Note that the security group should allow ssh/port 22 inbound traffic as this is how we connect to the machine.

Once the variables file has been created, you can run packer with: `packer build --var-file=packer_variables.json ../packer/base_vm.json`. Assuming this runs successfully you will have a new image to work with in the rest of the process (all this initial step does is make sure your base image is up-to-date).

### Create the slurm image
This step creates an image that the slurm database, controller and worker images will use. Simply run `packer build --var-file=packer_variables.json ../packer/slurm_base.json`

### Create the infrastrucure

Now you will need to create the VMs. The basic structure is:
1 × ldap server
1 × slurm database
1 × slurm controller
1 × login node
n × worker nodes

First copy the terraform `main.tf` file from the templates, i.e. `cp ../templates/main.tf`.

### Configure your services with ansible
Finally we use ansible to ensure everything is configured correctly.
