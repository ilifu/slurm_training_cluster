resource "openstack_networking_secgroup_v2" "galaxy_web" {
  name        = "secgroup_galaxy_web_${var.name_suffix}"
  description = "To access the galaxy web server"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.galaxy_web.id}"
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8443
  port_range_max    = 8443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.galaxy_web.id}"
}

# resource "openstack_networking_secgroup_v2" "secgroup_slurm_submit1" {
#   name        = "secgroup_slurm_submit1"
#   description = "My neutron slurm-submit-access security group"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_slurm_submit_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "udp"
#   port_range_min    = 60001
#   port_range_max    = 63000
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_slurm_submit1.id}"
# 

resource "openstack_networking_secgroup_v2" "galaxy_ntp" {
  name        = "secgroup_galaxy_ntp-${var.name_suffix}"
  description = "NTP Access"
}

resource "openstack_networking_secgroup_rule_v2" "ntp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 123
  port_range_max    = 123
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.galaxy_ntp.id}"
}

resource "openstack_networking_secgroup_v2" "galaxy_ssh" {
  name        = "secgroup_galaxy_ssh_${var.name_suffix}"
  description = "galaxy ssh-access security group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.galaxy_ssh.id}"
}

# resource "openstack_networking_secgroup_v2" "secgroup_http1" {
#   name        = "secgroup_http1"
#   description = "My neutron http and https-access security group"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_http_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 80
#   port_range_max    = 80
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_http1.id}"
# }
# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_https_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 443
#   port_range_max    = 443
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_http1.id}"
# }

# resource "openstack_networking_secgroup_v2" "secgroup_freeipa1" {
#   name        = "secgroup_freeipa1"
#   description = "My neutron freeipa-access security group (LDAP and Kerberos)"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_ldap_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 389
#   port_range_max    = 389
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_ldaps_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 636
#   port_range_max    = 636
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_kerberos_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 88
#   port_range_max    = 88
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_kerberos_rule_2" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 464
#   port_range_max    = 464
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_kerberos_rule_3" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "udp"
#   port_range_min    = 88
#   port_range_max    = 88
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_kerberos_rule_4" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "udp"
#   port_range_min    = 464
#   port_range_max    = 464
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_dns_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 53
#   port_range_max    = 53
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }
# resource "openstack_networking_secgroup_rule_v2" "secgroup_galaxy_dns_rule_2" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "udp"
#   port_range_min    = 53
#   port_range_max    = 53
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = "${openstack_networking_secgroup_v2.secgroup_freeipa1.id}"
# }

resource "openstack_networking_network_v2" "galaxy" {
    name = "galaxy-net_${var.name_suffix}"
    admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "galaxy" {
    name = "galaxy_subnet_${var.name_suffix}"
    network_id = "${openstack_networking_network_v2.galaxy.id}"
    cidr = "192.168.10.0/24"
    ip_version = 4
    enable_dhcp = "true"
    # allocation_pools = {
    #     start = "192.168.10.100", 
    #     end = "192.168.10.120"
    # }
    dns_nameservers = ["8.8.8.8"]
}

data "openstack_networking_network_v2" "public" {
  name = "Ext_Floating_IP"
}

# data "openstack_networking_network_v2" "ceph_network" {
#   name = "Ceph-net"
# }

resource "openstack_networking_router_v2" "galaxy" {
  name                = "galaxy_router_${var.name_suffix}"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.public.id}"
}


resource "openstack_networking_router_interface_v2" "galaxy" {
  router_id = "${openstack_networking_router_v2.galaxy.id}"
  subnet_id = "${openstack_networking_subnet_v2.galaxy.id}"
}
