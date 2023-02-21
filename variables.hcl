//  variables.pkr.hcl

// For those variables that you don't provide a default for, you must
// set them from the command line, a var-file, or the environment.

variable "image_name_prefix" {
  type = string
  description = "The prefix of the image name"
}

variable "image_name_suffix" {
  type = string
  description = "The suffix of the image name"
}

variable "build_flavor" {
  type = string
  description = "The flavor of the image used for building"
  default = "ilifu-B"
}

variable "ldap_image_name" {
  type = string
  description = "The name of the ldap image"
}

variable "database_image_name" {
  type = string
  description = "The name of the database image"
}

variable "source_image_id" {
  type = string
  description = "The source image"
}

variable "network_ids" {
  type = list(string)
  description = "The networks"
}

variable "floating_ip_network_id" {
  type = string
  description = "The floating ip network"
}

variable "security_groups_ids" {
  type = list(string)
  description = "The security groups"
}

variable "cluster_name" {
  type = string
  description = "The cluster name"
}

variable "organisation" {
  type = string
  description = "The organisation"
}

variable "database_flavor" {
  type = string
  description = "The database VM flavor"
}

variable "controller_flavor" {
  type = string
  description = "The controller VM flavor"
}

variable "ldap_flavor" {
  type = string
  description = "The ldap VM flavor"
}

variable "controller_host" {
  type = string
  description = "The controller host"
}

variable "database_host" {
  type = string
  description = "The database host"
}

variable "slurm_worker_node_name_prefix" {
  type = string
  description = "The slurm worker node name"
}

variable "slurm_worker_count" {
  type = string
  description = "The slurm worker count"
}

variable "slurm_worker_flavor" {
  type = string
  description = "The slurm worker VM flavor"
}

variable "ldap_host" {
  type = string
  description = "The ldap host"
}

variable "login_host" {
  type = string
  description = "The login host"
}

variable "login_flavor" {
  type = string
  description = "The login VM flavor"
}

variable "ldap_dns_domain_name" {
  type = string
  description = "The ldap dns domain name"
}

variable "ldap_organisation_name" {
  type = string
  description = "The ldap organization name"
}

variable "ldap_password" {
  type = string
  description = "The ldap password"
}

variable "ssh_public_key" {
  type = string
  description = "The ssh public key"
}

variable "ssh_key_location" {
  type = string
  description = "The ssh key location"
}

variable "cidr_prefix" {
  type = string
  description = "The cidr prefix"
}

variable "cidr_suffix" {
  type = string
  description = "The cidr suffix"
}

variable "floating_ip_pool_name" {
  type = string
  description = "The floating ip pool"
}

variable "ceph_net_name" {
  type = string
  description = "The ceph net name"
}

variable "ceph_subnet_name" {
  type = string
  description = "The ceph subnet name"
}
