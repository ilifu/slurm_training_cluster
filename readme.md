# [WIP]

## What is this?

This is a series of packer, terraform and ansible recipes/playbooks that will aid in creating a slurm cluster suitable for training events.
## How do I use it?
First you will need to download and install some pre-requisites including [Packer]() and [Terraform](). You will also need ansible running -- the recommended way for this is either installing your OS's ansible (e.g. `sudo apt install ansible`) or setting up a virtual environment and installing with pip, e.g.
```console
$ virtualenv -p python3 .venv
$ . .venv/bin/activate
$ pip install -r requirements.txt
```
Note this also installs the OpenStack CLI client which is potentially useful.

### Get your OpenStack RC File
Sign into the OpenStack Dashboard and then download your [OpenStack RC File](https://dashboard.ilifu.ac.za/project/api_access/). Once you have sourced this file (`. your-project-openrc.sh`) you may move on to creating the base image.

### Create your base image
Change to the packer directory and create your `variables.json` file using the template file, i.e. `cp variables.json.template variables.json`. Edit this file so that you have the appropriate IDs in place. Note if you installed the CLI client, then the commands you might use are:
`openstack flavor list`, `openstack image list`, `openstack network list` and `openstack security group list`. Note that the security group should allow ssh/port 22 inbound traffic as this is how we connect to the machine.

Once the variables file has been created, you can run packer with: `packer build --var-file=variables.json packer-base_galaxy_vm.json`. Assuming this runs successfully you will have a new image to work with in the rest of the process (all this initial step does is make sure your base image is up-to-date).

### Create the infrastructure with terraform
This step configures the basic structure of the install including setting up the galaxy host, the slurm head node and the compute images. First you should create the `terraform.tfvars` file using the provided template. You should indicate: the flavors of all the nodes; the number of compute nodes in the slurm cluster; and a suffix to use in the names of your resources (the compute instances, the network names, the security groups). Then run `terraform plan` to make sure everything is as you'd expect and finally `terraform apply` to create the infrastructure. 

### Configure your services with ansible
Finally we use ansible to ensure everything is configured correctly.
