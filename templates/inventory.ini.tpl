[all:vars]
ansible_connection=ssh
ansible_ssh_extra_args="-o ControlPersist=15m -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o AddKeysToAgent=no -o IdentitiesOnly=yes -v"
ansible_ssh_private_key_file=~/.ssh/ilifu/id_rsa
ansible_ssh_common_args='-o ProxyJump="ubuntu@${floating_ip.address}"'
ansible_user=ubuntu

[all:children]
ldap
slurm
slurm_database
slurm_controller
slurm_headnode
slurm_compute

[ldap]
ldap ansible_host=${ldap_node.access_ip_v4} private_ip=${ldap_node.access_ip_v4}

[slurm]
%{ for node in compute_nodes ~}
${ node.name } ansible_host=${node.access_ip_v4} private_ip=${node.access_ip_v4}
%{ endfor ~}
login ansible_host=${login_node.access_ip_v4} private_ip=${login_node.access_ip_v4}
controller ansible_host=${controller_node.access_ip_v4} private_ip=${controller_node.access_ip_v4}
database ansible_host=${database_node.access_ip_v4} private_ip=${database_node.access_ip_v4}

[slurm_database]
database ansible_host=${database_node.access_ip_v4} private_ip=${database_node.access_ip_v4}

[slurm_controller]
controller ansible_host=${controller_node.access_ip_v4} private_ip=${controller_node.access_ip_v4}

[slurm_headnode]
login ansible_host=${login_node.access_ip_v4} private_ip=${login_node.access_ip_v4}

[slurm_compute]
%{ for node in compute_nodes ~}
${ node.name } ansible_host=${node.access_ip_v4} private_ip=${node.access_ip_v4}
%{ endfor ~}

