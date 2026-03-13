resource "openstack_compute_keypair_v2" "cluster_ssh_key" {
  name       = "${var.image_name_prefix}-sshkey-${var.image_name_suffix}"
  public_key = var.ssh_public_key
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.ini.tpl",
    {
      compute_nodes = [for node in openstack_compute_instance_v2.compute_nodes.*: node ]
      database_node = openstack_compute_instance_v2.database_node
      login_node = openstack_compute_instance_v2.login_node
      controller_node = openstack_compute_instance_v2.controller_node
      ldap_node = openstack_compute_instance_v2.ldap_node
      floating_ip = openstack_networking_floatingip_v2.slurm_float_ip
      ssh_key_location = var.ssh_key_location
      password_login_enabled = var.password_login_enabled
    }
  )
  filename = "inventory.ini"
}

resource "local_file" "group_vars_all" {
  content = templatefile("templates/group_vars_all.tpl",
    {
      ldap_host = var.ldap_host
      ldap_dns_domain_name = var.ldap_dns_domain_name
      ldap_password = var.ldap_password
      ldap_organisation_name = var.ldap_organisation_name
    }
  )
  filename = "ansible/group_vars/all/terraform.yml"
}

resource "local_file" "group_vars_slurm" {
  content = templatefile("templates/group_vars_slurm.tpl",
    {
      cluster_name = var.cluster_name
      controller_host = var.controller_host
      database_host = var.database_host
      db_name = var.db_name
      slurm_username = var.slurm_username
      slurm_group_name = var.slurm_group_name
      slurm_db_password = var.slurm_db_password
      ceph_mounts = {
        home: {
          name: "home"
          mount_point: "/users"
          export_locations: openstack_sharedfilesystem_share_v2.home_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.home_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.home_share_access_rw.access_to
        }
        software: {
          name: "software"
          mount_point: "/software"
          export_locations: openstack_sharedfilesystem_share_v2.software_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.software_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.software_share_access_rw.access_to
        }
        data: {
          name: "data"
          mount_point: "/data"
          export_locations: openstack_sharedfilesystem_share_v2.data_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.data_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.data_share_access_rw.access_to
        }
        cbio: {
          name: "cbio"
          mount_point: "/cbio"
          export_locations: openstack_sharedfilesystem_share_v2.cbio_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.cbio_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.cbio_share_access_rw.access_to
        }
        ilifu: {
          name: "ilifu"
          mount_point: "/ilifu"
          export_locations: openstack_sharedfilesystem_share_v2.ilifu_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.ilifu_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.ilifu_share_access_rw.access_to
        }
        idia: {
          name: "idia"
          mount_point: "/idia"
          export_locations: openstack_sharedfilesystem_share_v2.idia_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.idia_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.idia_share_access_rw.access_to
        }
        cchem: {
          name: "cchem"
          mount_point: "/cchem"
          export_locations: openstack_sharedfilesystem_share_v2.cchem_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.cchem_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.cchem_share_access_rw.access_to
        }
        carta_fast: {
          name: "carta_fast"
          mount_point: "/carta_fast"
          export_locations: openstack_sharedfilesystem_share_v2.carta_fast_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.carta_fast_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.carta_fast_share_access_rw.access_to
        }
        carta_share: {
          name: "carta_share"
          mount_point: "/carta_share"
          export_locations: openstack_sharedfilesystem_share_v2.carta_share_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.carta_share_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.carta_share_share_access_rw.access_to
        }
        public: {
          name: "public"
          mount_point: "/public"
          export_locations: openstack_sharedfilesystem_share_v2.public_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.public_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.public_share_access_rw.access_to
        }
        scratch3: {
          name: "scratch3"
          mount_point: "/scratch3"
          export_locations: openstack_sharedfilesystem_share_v2.scratch3_share.export_locations,
          access: openstack_sharedfilesystem_share_access_v2.scratch3_share_access_rw.access_key,
          access_to: openstack_sharedfilesystem_share_access_v2.scratch3_share_access_rw.access_to
        }
      }
    }
  )
  filename = "ansible/group_vars/slurm/terraform.yml"
}
