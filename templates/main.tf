# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

provider "openstack" {
}

resource "openstack_compute_instance_v2" "ldap_server" {
  name            = "ldap"
  image_name      = "16s_training-base-dev"
  flavor_name     = "ilifu-A"
  key_pair        = "old_idia_key"
  security_groups = ["default"]

  network {
    name = "cbio-net"
  }
}

resource "openstack_compute_instance_v2" "database_server" {
  name            = "slurm_database"
  image_name      = "16s_training-slurm_base-dev"
  flavor_name     = "ilifu-A"
  key_pair        = "old_idia_key"
  security_groups = ["default"]

  network {
    name = "cbio-net"
  }
}

resource "openstack_compute_instance_v2" "slurm_controller" {
  name            = "slurm_controller"
  image_name      = "16s_training-slurm_base-dev"
  flavor_name     = "ilifu-A"
  key_pair        = "old_idia_key"
  security_groups = ["default"]

  network {
    name = "cbio-net"
  }
}

resource "openstack_compute_instance_v2" "slurm_login" {
  name            = "cbio.ilifu.ac.za"
  image_name      = "16s_training-slurm_base-dev"
  flavor_name     = "ilifu-A"
  key_pair        = "old_idia_key"
  security_groups = ["default", "SSH-only"]

  network {
    name = "cbio-net"
  }
}

resource "openstack_networking_floatingip_v2" "login_public_ip" {
  pool = "Ext_Floating_IP"
}

resource "openstack_compute_floatingip_associate_v2" "associate_external_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.login_public_ip.address}"
  instance_id = "${openstack_compute_instance_v2.slurm_login.id}"
}


