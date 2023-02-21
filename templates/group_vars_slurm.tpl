---
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
