resource "openstack_compute_instance_v2" "slurm_compute" {
  count           = "${var.slurm_compute_node_count}"
  name            = "galaxy_slurm_compute_${count.index}_${var.name_suffix}"
  image_name      = "dane-galaxy_base-ubuntu18.04.2"
  flavor_name     = "${var.slurm_compute_node_flavor}"
  key_pair        = "${openstack_compute_keypair_v2.my-cloud-key.name}"
  security_groups = ["${openstack_networking_secgroup_v2.galaxy_ssh.name}"]

  network {
    name = "${openstack_networking_network_v2.galaxy.name}"
  }

  provisioner "local-exec" {
    command = "hostname >> wtaf.txt"
  }
}

output "compute_instances" {
  description = "All the slurm compute nodes' names"
  value       = "${openstack_compute_instance_v2.slurm_compute.*.name}"
}

output "compute_ips" {
  description = "All the slurm compute nodes' ip addresses"
  value = "${openstack_compute_instance_v2.slurm_compute.*.access_ip_v4}"
}
