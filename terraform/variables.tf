variable "name_suffix" {
  type = string
  default = "dev"
  description = "A suffix to be used for all names - recommend dev/prod"
}

variable "slurm_compute_node_count" {
  type = number
  default = 2
  description = "Number of compute nodes to create"
}

variable "slurm_head_node_flavor" {
  type = string
  default = "ilifu-A"
  description = "Node flavor of the slurm head node"
}

variable "slurm_compute_node_flavor" {
  type = string
  default = "ilifu-A"
  description = "Node flavor of the compute nodes"
}

variable "galaxy_node_flavor" {
  type = string
  default = "ilifu-B"
  description = "Node flavor of the galaxy front end"
}
