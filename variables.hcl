//  variables.pkr.hcl

// For those variables that you don't provide a default for, you must
// set them from the command line, a var-file, or the environment.

variable "image_name_prefix" {
  type = string
  description = "The prefix of the image name"
  default = "training-"
}

variable "image_name_suffix" {
  type = string
  description = "The suffix of the image name"
  default = "-dev"
}

variable "build_flavor" {
  type = string
  description = "The flavor of the image used for building"
  default = "ilifu-B"
}

#variable "ldap_image_name" {
#  type = string
#  description = "The name of the ldap image"
#}
#
#variable "database_image_name" {
#  type = string
#  description = "The name of the database image"
#}

variable "source_image_name" {
  type = string
  description = "The source image name"
  default = "20250728-jammy"
}

variable "network_ids" {
  type = list(string)
  description = "The networks (only used when building image)"
}

variable "floating_ip_network_id" {
  type = string
  description = "The floating ip network"
  default = "f99ab9af-902c-494b-abfc-32ccd5716234"
}

variable "security_groups_ids" {
  type = list(string)
  description = "The security groups (only used when building image)"
}

variable "cluster_name" {
  type = string
  description = "The cluster name"
  default = "training"
}

#variable "organisation" {
#  type = string
#  description = "The organisation"
#}

variable "database_flavor" {
  type = string
  description = "The database VM flavor"
  default = "ilifu-B"
}

variable "controller_flavor" {
  type = string
  description = "The controller VM flavor"
  default="ilifu-B"
}

variable "ldap_flavor" {
  type = string
  description = "The ldap VM flavor"
  default = "ilifu-A"
}

variable "controller_host" {
  type = string
  description = "The controller host"
  default= "controller"
}

variable "database_host" {
  type = string
  description = "The database host"
  default = "database"
}

variable "slurm_worker_node_name_prefix" {
  type = string
  description = "The slurm worker node name"
  default = "compute"
}

variable "slurm_worker_count" {
  type = string
  description = "The slurm worker count"
  default = "6"
}

variable "slurm_worker_flavor" {
  type = string
  description = "The slurm worker VM flavor"
  default = "ilifu-G-240G"
}

variable "ldap_host" {
  type = string
  description = "The ldap host"
  default = "ldap"
}

variable "login_host" {
  type = string
  description = "The login host"
  default = "login"
}

variable "login_flavor" {
  type = string
  description = "The login VM flavor"
  default = "ilifu-B"
}

variable "ldap_dns_domain_name" {
  type = string
  description = "The ldap dns domain name"
  default = "training.ilifu.ac.za"
}

variable "ldap_organisation_name" {
  type = string
  description = "The ldap organization name"
  default = "training"
}

variable "ldap_password" {
  type = string
  description = "The ldap password"
  sensitive = true
  default = "youshouldprobablychangethis"
}

variable "slurm_db_password" {
  type = string
  description = "The slurm db password"
  sensitive = true
  default = "youshouldprobablychangethis"
}

variable "ssh_public_key" {
  type = string
  description = "The ssh public key"
}

variable "ssh_key_location" {
  type = string
  description = "The ssh key location"
  default = "~/.ssh/id_ed25519"
}

variable "cidr_prefix" {
  type = string
  description = "The cidr prefix"
  default = "192.168.20.0"
}

variable "cidr_suffix" {
  type = string
  description = "The cidr suffix"
  default = "24"
}

variable "floating_ip_pool_name" {
  type = string
  description = "The floating ip pool"
  default = "Ext_Floating_IP"
}

variable "ceph_net_name" {
  type = string
  description = "The ceph net name"
  default = "Ceph-net"
}

variable "ceph_subnet_name" {
  type = string
  description = "The ceph subnet name"
  default = "Ceph-subnet"
}

variable "db_name" {
  type = string
  description = "The slurmdb name"
  default = "slurmdb"
}

variable "slurm_username" {
    type = string
    description = "The slurm username"
    default = "slurm"
}

variable "slurm_group_name" {
    type = string
    description = "The slurm group name"
    default = "slurm"
}

variable "node_name_suffix" {
    type = string
    description = "Suffix to append to node names"
    default = ""
}

variable "software_share_size" {
    type = number
    description = "Size of the software CephFS share in GB"
    default = 20
}

variable "home_share_size" {
    type = number
    description = "Size of the home directories CephFS share in GB"
    default = 50
}

variable "data_share_size" {
    type = number
    description = "Size of the data CephFS share in GB"
    default = 5120
}
