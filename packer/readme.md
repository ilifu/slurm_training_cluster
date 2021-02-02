# Packer image

This image is to build a base image that both galaxy and slurm will use and provision during ansible. Everything installed in this image should be installed/verified with the ansible playbook, the thinking behind this is simply to speed up the final provisioning.

## To use
First be sure to source the OpenStack rc file (and be sure to have your OpenStack password at hand), e.g.
```console
$ . ~/YourProject-openrc.sh
```
This will configure the various `OS_` environment variables that packer needs.
Adapt the file to your own needs -- fill in the various IDs for: `source_image`, `networks`, `floating_ip_network`, `security_groups` (your security group should be configured to allow `ssh` [port 22] ingress at a minumum).

The image will have the source ubuntu's operating system upgraded and various known dependencies installed.