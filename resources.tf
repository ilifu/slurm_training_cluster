resource "openstack_compute_keypair_v2" "gen3_ssh_key" {
  name       = "${var.name_prefix}-sshkey"
  public_key = var.ssh_public_key
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/inventory.ini.tpl",
    {
      gen3_hostname = var.gen3_hostname
      k8s_node_float_ip = openstack_networking_floatingip_v2.k8s_float_ip.address
      k8s_nodes = [for node in openstack_compute_instance_v2.k8s_nodes.*: node ]
      k8s_control_plane = openstack_compute_instance_v2.k8s_control_plane
      database_node = openstack_compute_instance_v2.database_node
      admin_user = var.admin_user
      postgres_user = var.postgres_user
      postgres_password = var.postgres_password
      postgres_fence_user = var.postgres_fence_user
      postgres_fence_password = var.postgres_fence_password
      postgres_peregrine_user = var.postgres_peregrine_user
      postgres_peregrine_password = var.postgres_peregrine_password
      postgres_sheepdog_user = var.postgres_sheepdog_user
      postgres_sheepdog_password = var.postgres_sheepdog_password
      postgres_indexd_user = var.postgres_indexd_user
      postgres_indexd_password = var.postgres_indexd_password
      postgres_arborist_user = var.postgres_arborist_user
      postgres_arborist_password = var.postgres_arborist_password
    }
  )
  filename = "inventory.ini"
}

resource "local_file" "group_vars_all" {
  content = templatefile("templates/group_vars.tpl",
    {
       cluster_name = var.cluster_name
       organisation = var.organisation
       controller_host = var.controller_host
       database_host = var.database_host
       ldap_host = var.ldap_host
       ldap_dns_domain_name = var.ldap_dns_domain_name
       ldap_password_env_variable = var.ldap_password_env_variable
    }
  )
  filename = "ansible/group_vars/all/terraform.yml"
}
