resource "openstack_compute_instance_v2" "database_node" {
  name            = var.database_host
  image_name      = local.database_image_name
  flavor_name     = var.database_flavor
  key_pair        = openstack_compute_keypair_v2.cluster_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.slurm_nodes.name]
  network {
    name = openstack_networking_network_v2.slurm_network.name
  }
}

resource "openstack_compute_instance_v2" "controller_node" {
  name            = var.controller_host
  image_name      = local.slurm_base_image_name
  flavor_name     = var.controller_flavor
  key_pair        = openstack_compute_keypair_v2.cluster_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.slurm_nodes.name]
  network {
    name = openstack_networking_network_v2.slurm_network.name
  }
}

resource "openstack_compute_instance_v2" "login_node" {
  name            = var.login_host
  image_name      = local.slurm_base_image_name
  flavor_name     = var.login_flavor
  key_pair        = openstack_compute_keypair_v2.cluster_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.slurm_nodes.name, openstack_networking_secgroup_v2.slurm_ssh.name]
  network {
    name = openstack_networking_network_v2.slurm_network.name
  }
}

resource "openstack_compute_floatingip_associate_v2" "slurm_fip" {
  floating_ip = openstack_networking_floatingip_v2.slurm_float_ip.address
  instance_id = openstack_compute_instance_v2.login_node.id
}

resource "openstack_compute_instance_v2" "compute_nodes" {
  count           = var.slurm_worker_count
  name            = "${ var.slurm_worker_node_name_prefix }-${ count.index + 1 }"
  image_name      = local.slurm_base_image_name
  flavor_name     = var.slurm_worker_flavor
  key_pair        = openstack_compute_keypair_v2.cluster_ssh_key.name
  security_groups = [openstack_networking_secgroup_v2.slurm_nodes.name]
  network {
    name = openstack_networking_network_v2.slurm_network.name
  }
}
