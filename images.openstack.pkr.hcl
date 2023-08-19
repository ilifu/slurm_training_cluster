locals {
  base_image_name = "${var.image_name_prefix}base${var.image_name_suffix}"
  slurm_base_image_name = "${var.image_name_prefix}slurm-base${var.image_name_suffix}"
  ldap_image_name = "${var.image_name_prefix}ldap${var.image_name_suffix}"
  database_image_name = "${var.image_name_prefix}database${var.image_name_suffix}"
}

source "openstack" "base_image" {
  flavor       = "${var.build_flavor}"
  image_name   = "${local.base_image_name}"
  source_image = "${var.source_image_id}"
#  external_source_image_format = "qcow2"
  ssh_username = "ubuntu"
  networks = "${var.network_ids}"
  floating_ip_network = "${var.floating_ip_network_id}"
  security_groups = "${var.security_groups_ids}"
  metadata = {
    hw_disk_bus = "scsi"
    hw_qemu_guest_agent = "yes",
    hw_rng_model = "virtio",
    hw_scsi_model = "virtio-scsi",
    hw_vif_model = "virtio"
  }
}

source "openstack" "slurm_image" {
  flavor       = "${var.build_flavor}"
  image_name   = "${local.slurm_base_image_name}"
  source_image_name = "${local.base_image_name}"
#  external_source_image_format = "qcow2"
  ssh_username = "ubuntu"
  networks = "${var.network_ids}"
  floating_ip_network = "${var.floating_ip_network_id}"
  security_groups = "${var.security_groups_ids}"
  metadata = {
    hw_disk_bus = "scsi"
    hw_qemu_guest_agent = "yes",
    hw_rng_model = "virtio",
    hw_scsi_model = "virtio-scsi",
    hw_vif_model = "virtio"
  }
}

source "openstack" "ldap_image" {
  flavor       = "${var.build_flavor}"
  image_name   = "${local.ldap_image_name}"
  source_image_name = "${local.base_image_name}"
#  external_source_image_format = "qcow2"
  ssh_username = "ubuntu"
  networks = "${var.network_ids}"
  floating_ip_network = "${var.floating_ip_network_id}"
  security_groups = "${var.security_groups_ids}"
  metadata = {
    hw_disk_bus = "scsi"
    hw_qemu_guest_agent = "yes",
    hw_rng_model = "virtio",
    hw_scsi_model = "virtio-scsi",
    hw_vif_model = "virtio"
  }
}

source "openstack" "database_image" {
  flavor       = "${var.build_flavor}"
  image_name   = "${local.database_image_name}"
  source_image_name = "${local.slurm_base_image_name}"
#  external_source_image_format = "qcow2"
  ssh_username = "ubuntu"
  networks = "${var.network_ids}"
  floating_ip_network = "${var.floating_ip_network_id}"
  security_groups = "${var.security_groups_ids}"
  metadata = {
    hw_disk_bus = "scsi"
    hw_qemu_guest_agent = "yes",
    hw_rng_model = "virtio",
    hw_scsi_model = "virtio-scsi",
    hw_vif_model = "virtio"
  }
}

build {
  name = "step1"
  sources = [
    "source.openstack.base_image"
   ]
  provisioner "ansible" {
    use_proxy = false
    playbook_file = "./ansible/site.yaml"
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    extra_arguments = ["--tags", "build"]
    user = "ubuntu"
    groups = ["base", "common"]
  }
}

build {
  name = "step2"
  sources = [
    "source.openstack.slurm_image"
   ]
  provisioner "ansible" {
    use_proxy = false
    playbook_file = "./ansible/site.yaml"
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    extra_arguments = ["--tags", "build"]
    user = "ubuntu"
    groups = ["slurm"]
  }
}

build {
  name = "step3"
  sources = [
    "source.openstack.ldap_image"
   ]
  provisioner "ansible" {
    use_proxy = false
    playbook_file = "./ansible/site.yaml"
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    extra_arguments = ["--tags", "build"]
    user = "ubuntu"
    groups = ["ldap"]
  }
}

build {
  name = "step4"
  sources = [
    "source.openstack.database_image"
   ]
  provisioner "ansible" {
    use_proxy = false
    playbook_file = "./ansible/site.yaml"
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes'"
    ]
    extra_arguments = ["--tags", "build"]
    user = "ubuntu"
    groups = ["slurm_database"]
  }
}
