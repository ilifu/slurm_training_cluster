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

variable "base_image_name" {
  type = string
  description = "The name of the base image"
}

variable "ldap_image_name" {
  type = string
  description = "The name of the ldap image"
}

variable "slurm_base_image_name" {
  type = string
  description = "The name of the slurm base image"
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

#variable "slurm_version" {
#  type = string
#  description = "The slurm version"
#}
#
#variable "slurm_version_git" {
#  type = string
#  description = "The slurm version git"
#}

variable "cluster_name" {
  type = string
  description = "The cluster name"
}

variable "organisation" {
  type = string
  description = "The organisation"
}

variable "controller_host" {
  type = string
  description = "The controller host"
}

variable "database_host" {
  type = string
  description = "The database host"
}

#variable "slurm_user" {
#  type = string
#  description = "The slurm user"
#}
#
#variable "slurm_group" {
#  type = string
#  description = "The slurm group"
#}
#
#variable "slurm_db_name" {
#  type = string
#  description = "The slurm db name"
#}
#
#variable "slurm_db_user" {
#  type = string
#  description = "The slurm db user"
#}
#
#variable "slurm_db_password_env_var" {
#  type = string
#  description = "The slurm db password"
#}
#
#variable "slurm_dbd_port" {
#  type = string
#  description = "The slurm dbd port"
#}
#
#variable "slurm_ctld_port" {
#  type = string
#  description = "The slurm ctld port"
#}
#
#variable "slurm_slurmd_port" {
#  type = string
#  description = "The slurm slurmd port"
#}
#
#variable "slurm_spool_dir" {
#  type = string
#  description = "The slurm spool dir"
#}

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
  description = "The slurm worker flavor"
}

variable "ldap_host" {
  type = string
  description = "The ldap host"
}

variable "ldap_dns_domain_name" {
  type = string
  description = "The ldap dns domain name"
}

variable "ldap_password_env_variable" {
  type = string
  description = "The ldap password"
}
