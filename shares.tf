resource "openstack_sharedfilesystem_share_v2" "software_share" {
  name             = "${ var.image_name_prefix }_software_${ var.image_name_suffix }"
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
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "home_share" {
  name             = "${ var.image_name_prefix }_home_${ var.image_name_suffix }"
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
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "data_share" {
  name             = "${ var.image_name_prefix }_data_${ var.image_name_suffix }"
  description      = "shared fs for data"
  share_proto      = "CEPHFS"
  share_type       = "cephfs"
  size             = var.data_share_size
  availability_zone = "nova"
#  share_network_id = "${openstack_sharedfilesystem_sharenetwork_v2.cephfs_sharenetwork.id}"
}

resource "openstack_sharedfilesystem_share_access_v2" "data_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.data_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "cbio_share" {
  name              = "${ var.image_name_prefix }_cbio_${ var.image_name_suffix }"
  description       = "shared fs for cbio"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.cbio_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "cbio_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.cbio_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "ilifu_share" {
  name              = "${ var.image_name_prefix }_ilifu_${ var.image_name_suffix }"
  description       = "shared fs for ilifu"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.ilifu_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "ilifu_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.ilifu_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "idia_share" {
  name              = "${ var.image_name_prefix }_idia_${ var.image_name_suffix }"
  description       = "shared fs for idia"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.idia_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "idia_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.idia_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "cchem_share" {
  name              = "${ var.image_name_prefix }_cchem_${ var.image_name_suffix }"
  description       = "shared fs for cchem"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.cchem_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "cchem_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.cchem_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "carta_fast_share" {
  name              = "${ var.image_name_prefix }_carta_fast_${ var.image_name_suffix }"
  description       = "shared fs for carta_fast"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.carta_fast_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "carta_fast_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.carta_fast_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "carta_share_share" {
  name              = "${ var.image_name_prefix }_carta_share_${ var.image_name_suffix }"
  description       = "shared fs for carta_share"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.carta_share_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "carta_share_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.carta_share_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "public_share" {
  name              = "${ var.image_name_prefix }_public_${ var.image_name_suffix }"
  description       = "shared fs for public"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.public_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "public_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.public_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_v2" "scratch3_share" {
  name              = "${ var.image_name_prefix }_scratch3_${ var.image_name_suffix }"
  description       = "shared fs for scratch3"
  share_proto       = "CEPHFS"
  share_type        = "cephfs"
  size              = var.scratch3_share_size
  availability_zone = "nova"
}

resource "openstack_sharedfilesystem_share_access_v2" "scratch3_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.scratch3_share.id
  access_type  = "cephx"
  access_to    = "${ var.image_name_prefix }_slurm_users_${ var.image_name_suffix }_rw"
  access_level = "rw"
}
