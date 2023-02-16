resource "openstack_networking_network_v2" "slurm_network" {
    name = "${var.image_name_prefix}-net"
    admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "slurm_subnet" {
    name = "${var.image_name_prefix}-subnet"
    network_id = openstack_networking_network_v2.slurm_network.id
    cidr = "${var.cidr_prefix}/${var.cidr_suffix}"
    ip_version = 4
    enable_dhcp = "true"
    dns_nameservers = ["8.8.8.8"]
}

data "openstack_networking_network_v2" "public" {
  name = var.floating_ip_pool_name
}

resource "openstack_networking_floatingip_v2" "slurm_float_ip" {
  pool = var.floating_ip_pool_name
}

resource "openstack_networking_router_v2" "slurm_router" {
  name                = "${var.image_name_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public.id
}


resource "openstack_networking_router_interface_v2" "slurm_router_interface" {
  router_id = openstack_networking_router_v2.slurm_router.id
  subnet_id = openstack_networking_subnet_v2.slurm_subnet.id
}

resource "openstack_networking_secgroup_v2" "slurm_ssh" {
  name        = "${var.image_name_prefix}-ssh"
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
  name        = "${var.image_name_prefix}-slurm-nodes"
  description = "ports that need to be open for all internal slurm traffic"
}

resource "openstack_networking_secgroup_rule_v2" "internal_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${var.cidr_prefix}/${var.cidr_suffix}"
  security_group_id = openstack_networking_secgroup_v2.slurm_nodes.id
}

resource "openstack_networking_secgroup_rule_v2" "slurmd" {
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 6817
  port_range_max   = 6819
  remote_ip_prefix = "${var.cidr_prefix}/${var.cidr_suffix}"
  security_group_id = openstack_networking_secgroup_v2.slurm_nodes.id
}
