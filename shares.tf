resource "openstack_sharedfilesystem_share_v2" "software_share" {
  name             = "${ var.image_name_prefix }_software"
  description      = "shared fs for software"
  share_proto      = "CEPHFS"
  share_type       = "cephfs"
  size             = var.software_share_size
  availability_zone = "nova"
#  share_network_id = "${openstack_sharedfilesystem_sharenetwork_v2.cephfs_sharenetwork.id}"
}

resource "openstack_sharedfilesystem_share_access_v2" "software_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.software_share.id
  access_type  = "cephx"
  access_to    = "slurm_users_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "home_share" {
  name             = "${ var.image_name_prefix }_home"
  description      = "shared fs for user home directories"
  share_proto      = "CEPHFS"
  share_type       = "cephfs"
  size             = var.home_share_size
  availability_zone = "nova"
#  share_network_id = "${openstack_sharedfilesystem_sharenetwork_v2.cephfs_sharenetwork.id}"
}

resource "openstack_sharedfilesystem_share_access_v2" "home_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.home_share.id
  access_type  = "cephx"
  access_to    = "slurm_users_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "data_share" {
  name             = "${ var.image_name_prefix }_data"
  description      = "shared fs for user home directories"
  share_proto      = "CEPHFS"
  share_type       = "cephfs"
  size             = var.data_share_size
  availability_zone = "nova"
#  share_network_id = "${openstack_sharedfilesystem_sharenetwork_v2.cephfs_sharenetwork.id}"
}

resource "openstack_sharedfilesystem_share_access_v2" "data_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.data_share.id
  access_type  = "cephx"
  access_to    = "slurm_users_rw"
  access_level = "rw"
}
