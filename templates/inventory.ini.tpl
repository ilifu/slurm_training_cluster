[all:vars]
ansible_connection=ssh
ansible_ssh_extra_args="-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v"
ansible_ssh_private_key_file=~/.ssh/ilifu/id_rsa
ansible_user=ubuntu

[all:children]
ldap
slurm
slurm_database
slurm_controller
slurm_headnode
slurm_compute

[ldap]

[slurm]
%{ for node in compute_nodes ~}
${ node.name } ansible_host=${node.access_ip_v4} private_ip=${node.access_ip_v4}
%{ endfor ~}

[slurm_database]

[slurm_controller]

[slurm_headnode]

[slurm_compute]
%{ for node in compute_nodes ~}
${ node.name } ansible_host=${node.access_ip_v4} private_ip=${node.access_ip_v4}
%{ endfor ~}

