for i in {02..45}; do echo \
"  - user$i:
    username: user$i
    uid: 200$i
    gid: 200$i
    ssh_public_key:"
done >> main.yml

