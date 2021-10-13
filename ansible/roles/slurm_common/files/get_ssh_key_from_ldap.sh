#!/bin/bash
ldapsearch -x '(&(objectClass=posixAccount)(uid='"$1"'))' 'sshPublicKey' | sed -n '/^ /{H;d};/sshPublicKey:/x;$g;s/\n *//g;s/sshPublicKey: //gp'