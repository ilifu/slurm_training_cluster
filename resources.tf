resource "openstack_compute_keypair_v2" "cluster_ssh_key" {
  name       = "${var.image_name_prefix}-sshkey"
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
