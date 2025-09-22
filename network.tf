resource "openstack_networking_network_v2" "slurm_network" {
    name = "${var.image_name_prefix}-net-${var.image_name_suffix}"
    admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "slurm_subnet" {
    name = "${var.image_name_prefix}-subnet-${var.image_name_suffix}"
    network_id = openstack_networking_network_v2.slurm_network.id
    cidr = "${var.cidr_prefix}/${var.cidr_suffix}"
    ip_version = 4
    enable_dhcp = "true"
    dns_nameservers = ["8.8.8.8"]
}

data "openstack_networking_network_v2" "public" {
  name = var.floating_ip_pool_name
}

data "openstack_networking_network_v2" "ceph_net" {
  name = var.ceph_net_name
}

data "openstack_networking_subnet_v2" "ceph_subnet" {
  name = var.ceph_subnet_name
}

resource "openstack_networking_floatingip_v2" "slurm_float_ip" {
  pool = var.floating_ip_pool_name
}

resource "openstack_networking_router_v2" "slurm_router" {
  name                = "${var.image_name_prefix}-router-${var.image_name_suffix}"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "slurm_router_interface" {
  router_id = openstack_networking_router_v2.slurm_router.id
  subnet_id = openstack_networking_subnet_v2.slurm_subnet.id
}

resource "openstack_networking_secgroup_v2" "slurm_ssh" {
  name        = "${var.image_name_prefix}-ssh-${var.image_name_suffix}"
  description = "To access login node"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.slurm_ssh.id
}

resource "openstack_networking_secgroup_v2" "slurm_nodes" {
  name        = "${var.image_name_prefix}-slurm-nodes-${var.image_name_suffix}"
  description = "ports that need to be open for all internal slurm traffic"
}

#resource "openstack_networking_secgroup_rule_v2" "internal_ssh" {
#  direction         = "ingress"
#  ethertype         = "IPv4"
#  protocol          = "tcp"
#  port_range_min    = 22
#  port_range_max    = 22
#  remote_ip_prefix  = "${var.cidr_prefix}/${var.cidr_suffix}"
#  security_group_id = openstack_networking_secgroup_v2.slurm_nodes.id
#}

resource "openstack_networking_secgroup_rule_v2" "everything_internal_open" {
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_ip_prefix = "${var.cidr_prefix}/${var.cidr_suffix}"
  security_group_id = openstack_networking_secgroup_v2.slurm_nodes.id
}

#resource "openstack_networking_secgroup_v2" "slurm_db" {
#  name        = "${var.image_name_prefix}-slurm-db"
#  description = "ports that need to be open for slurmdbd"
#}

#resource "openstack_networking_secgroup_rule_v2" "slurmdbd" {
#  direction        = "ingress"
#  ethertype        = "IPv4"
#  protocol         = "tcp"
#  port_range_min   = 7031
#  port_range_max   = 7031
#  remote_ip_prefix = "${var.cidr_prefix}/${var.cidr_suffix}"
#  security_group_id = openstack_networking_secgroup_v2.slurm_db.id
#}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "icmp"
  remote_ip_prefix = "${var.cidr_prefix}/${var.cidr_suffix}"
  security_group_id = openstack_networking_secgroup_v2.slurm_nodes.id
}

#resource "openstack_networking_secgroup_v2" "ldap_server" {
#  name        = "${var.image_name_prefix}-ldap-server"
#  description = "ports that need to be open for ldap traffic to server"
#}

#resource "openstack_networking_secgroup_rule_v2" "ldap_server" {
#  direction         = "ingress"
#  ethertype         = "IPv4"
#  protocol          = "tcp"
#  port_range_min    = 389
#  port_range_max    = 389
#  remote_ip_prefix  = "${var.cidr_prefix}/${var.cidr_suffix}"
#  security_group_id = openstack_networking_secgroup_v2.ldap_server.id
#}

#resource "openstack_networking_secgroup_rule_v2" "ldap_tls" {
#  direction         = "ingress"
#  ethertype         = "IPv4"
#  protocol          = "tcp"
#  port_range_min    = 636
#  port_range_max    = 636
#  remote_ip_prefix  = "${var.cidr_prefix}/${var.cidr_suffix}"
#  security_group_id = openstack_networking_secgroup_v2.ldap_server.id
#}
