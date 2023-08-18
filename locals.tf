locals {
  base_image_name = "${var.image_name_prefix}base${var.image_name_suffix}"
  slurm_base_image_name = "${var.image_name_prefix}slurm-base${var.image_name_suffix}"
  ldap_image_name = "${var.image_name_prefix}ldap${var.image_name_suffix}"
  database_image_name = "${var.image_name_prefix}database${var.image_name_suffix}"
}
