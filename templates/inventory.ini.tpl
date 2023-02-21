[all:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ControlPersist=15m -i ${ssh_key_location}'
ansible_ssh_extra_args="-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o ControlPersist=15m -A -i ${ssh_key_location} ubuntu@${floating_ip.address} nc %h 22'"
ansible_ssh_private_key_file=${ssh_key_location}
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

