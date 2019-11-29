#!/bin/bash
usage ()
{
cat << EOF
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$(echo "sudo $(basename "$0") -n [node_name] -r [ram(MB)] -c [cpu count] -u [ubuntu | centos] (default - ubuntu) | -h [this hint]")
$(echo "OPTIONS:
  -n  created node hostname
  -r  RAM 
  -c  cpu count
  -u  username and OS * Optional default option - ubuntu"
)

Example:
$(echo "sudo $(basename "$0") -n node1 -r 5000 -c 3") 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
}

function update_public_network {
     # set static ip address for node    \/ change this
cmac=$(virsh domiflist ${node} | awk '/virbr0/ {print $5; exit}')
echo $cmac; echo $IP_ADDR
virsh net-update "${net_name}" add ip-dhcp-host \
    "<host mac='${cmac}' ip='${IP_ADDR}'/>" --live --config
}


function prepare_vms {
  local base_image=$1; shift
  local image_dir=$1; shift
  local image="$image1"
  local vcp_image=${image%.*}_vcp.img
  local _o=${base_image/*\/}
  local _tmp

function get_base_image {
local base_image=$1
local image_dir=$2
wget --progress=dot:giga -P "${image_dir}" -N "${base_image}"
}
      get_base_image "${base_image}" "${image_dir}"
    ./create-config-drive.sh -k ~/.ssh/id_rsa.pub \
       -u "${user_data}" -h "${node}" "${image_dir}/${node}.iso"
    cp "${image_dir}/${image}" "${image_dir}/${node}.qcow2"
    qemu-img resize "${image_dir}/${node}.qcow2" 100G
}

function create_vms {
  local image_dir=$1; shift

net_args="--network bridge=${net_bridge},model=virtio"
#--network bridge=ub16,model=virtio"
#--network bridge=virbr0,model=virtio --network bridge=virbr0,model=virtio --network bridge=mngbr0,model=virtio"

    virt-install --name "${node}" \
    --ram "${ram}" --vcpus "${cpu}" \
    --cpu host-passthrough --accelerate ${net_args} \
    --disk path="${image_dir}/${node}.qcow2",format=qcow2,bus=virtio,cache=none,io=native \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path="${image_dir}/${node}.iso",device=cdrom \
    --noautoconsole \
    ${virt_extra_args}
}
