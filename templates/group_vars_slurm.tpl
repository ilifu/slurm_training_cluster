---
cluster_name: "${cluster_name}"
controller_host: "${controller_host}"
database_host: "${database_host}"
ceph_mounts:
%{ for mount in ceph_mounts ~}
  - ${ mount.name }:
    name: "${ mount.name }"
    export_locations:
%{ for location in mount.export_locations ~}
      - "${ location.path }"
%{ endfor ~}
    access_key: "${ mount.access }"
    access_to: "${ mount.access_to }"
    mount_point: "${ mount.mount_point }"
%{ endfor ~}

slurm_config:
  cluster_name: "${cluster_name}"
  controller_host: "${controller_host}"
  database_host: "${database_host}"
  slurm_db_password: "${slurm_db_password}"
  db_name: "${db_name}"
  username: "${slurm_username}"
  group_name: "${slurm_group_name}"

