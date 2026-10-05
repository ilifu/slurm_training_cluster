[all:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ControlPersist=15m -i ${ssh_key_location}'
ansible_ssh_extra_args="-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o ControlPersist=15m -A -i ${ssh_key_location} ubuntu@${floating_ip_address} nc %h 22'"
ansible_ssh_private_key_file=${ssh_key_location}
ansible_user=ubuntu

[all:children]
ldap_server
slurm

[ldap_server]
ldap ansible_host=${ldap_ip} private_ip=${ldap_ip}

[slurm]
[slurm:children]
slurm_database
slurm_controller
slurm_headnode
slurm_compute

[slurm_database]
database ansible_host=${database_ip} private_ip=${database_ip}

[slurm_controller]
controller ansible_host=${controller_ip} private_ip=${controller_ip}

[slurm_headnode]
login ansible_host=${floating_ip_address} private_ip=${login_ip}

[slurm_headnode:vars]
ansible_ssh_extra_args=""
password_login_enabled=${password_login_enabled}

[slurm_compute]
%{ for node in compute_nodes ~}
${ node.name } ansible_host=${node.ip} private_ip=${node.ip}
%{ endfor ~}

