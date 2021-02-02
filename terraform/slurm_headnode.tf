resource "openstack_compute_instance_v2" "slurm_headnode" {
  count           = 1
  name            = "galaxy_slurm_headnode_${var.name_suffix}"
  image_name      = "dane-galaxy_base-ubuntu18.04.2"
  flavor_name     = "${var.slurm_head_node_flavor}"
  key_pair        = "${openstack_compute_keypair_v2.my-cloud-key.name}"
  security_groups = [
    "${openstack_networking_secgroup_v2.galaxy_ntp.name}",
    "${openstack_networking_secgroup_v2.galaxy_ssh.name}",
    ]

  network {
    name = "${openstack_networking_network_v2.galaxy.name}"
  }
}
