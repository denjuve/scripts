#!/bin/bash
usage ()
{
cat << EOF
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
$(echo "sudo $(basename "$0") -n [node_name] -r [ram(MB)] -c [cpu count] -u [ubuntu | centos] (default - ubuntu) | -h [this hint]")
$(echo "OPTIONS:
  -n  VM hostname
  -r  RAM (MB) 
  -c  cpu count
  -u  username and OS * Optional default option - ubuntu
  -i  ip address for ctreated net (only in single net case) default value is 10.77.101.100
  -N  attached network options: default is for default libvirt network, number 2..18 is for attached networks quantity
")

Example:
$(echo "sudo $(basename "$0") -n node1 -r 5000 -c 3 -u ubuntu -i 10.77.101.250") 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
}

function get_base_image {
local base_image=$1
local image_dir=$2
wget --progress=dot:giga -P "${image_dir}" -N "${base_image}"
}

function prepare_vms {
  local base_image=$1; shift
  local image_dir=$1; shift
  local image="$image1"
  local vcp_image=${image%.*}_vcp.img
  local _o=${base_image/*\/}
  local _tmp

      get_base_image "${base_image}" "${image_dir}"
    ./create-config-drive.sh -k ~/.ssh/id_rsa.pub \
       -u "${user_data}" -h "${node}" "${image_dir}/${node}.iso"
    cp "${image_dir}/${image}" "${image_dir}/${node}.qcow2"
    qemu-img resize "${image_dir}/${node}.qcow2" 100G
}

function create_networks {
  if [[ $NETWORK == "default" ]]; then
    echo "Default network specified, no net cration needed"
  else
  cn_net=("$@")
  for net in "${cn_net[@]}"; do
cat <<EOF > ${net}.xml
<network>
  <name>${net}</name>
  <uuid>$(uuidgen)</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='${net}' stp='on' delay='0'/>
  <ip address='10.${net}.101.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.${net}.101.2' end='10.${net}.101.254'/>
    </dhcp>
  </ip>
</network>
EOF
    virsh net-define ${net}.xml
    virsh net-autostart ${net}
    virsh net-start ${net}
    rm -f ${net}.xml
  done
fi
}

function create_vms {
  local image_dir=$1; shift
  if [[ $NETWORK == "default" ]]; then
    net_args="--network bridge=virbr0,model=virtio"
  else
    NET_ARGS=()
    for net_a in ${cn_net[@]}; do
      net_argument=" --network bridge=${net_a},model=virtio"
      NET_ARGS+=($net_argument)
    done
    net_args="${NET_ARGS[*]}"        ##" --network bridge=virbr0,model=virtio --network bridge=mngbr0,model=virtio"
  fi

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

function update_public_network {

  ##for net in ${ARRAY[@]}; do
  # !!!Default network options
  if [[ $NETWORK == "default" ]]; then
    cmac=$(virsh domiflist ${node} |grep default | awk '{print $5}')
    echo "mac: $cmac"; echo "ip: $ip_addr"
  elif [[ $NETWORK == "default" ]] && [ -n "${ip_addr}" ]; then
    cmac=$(virsh domiflist ${node} |grep default | awk '{print $5}')
    virsh net-update ${net} add ip-dhcp-host \
        "<host mac='${cmac}' ip='${ip_addr}'/>" --live --config
  
  # !!!Custom IP in a single arbitrary network***
  elif [ -n "${ip_addr}" ] && [ ${#cn_net[@]} == 1 ]; then
  ARRAY=()
  for i in ${cn_net[@]}; do
    echo "net${i} is: $i"; ARRAY+=(10.${i}.101.100)
  done
  echo "nets are: ${cn_net[@]}";echo "IP(s) in nets are ${ARRAY[@]}"
    local ip_addr=$1
    cmac=$(virsh domiflist ${node} |grep "${cn_net[0]}" | awk '{print $5}')   #cmac=$(virsh domiflist ${node} | awk 'FNR == 3 {print $5}')
    echo "mac: $cmac"; echo "ip: $ip_addr"
    virsh net-update ${net} add ip-dhcp-host \
        "<host mac='${cmac}' ip='${ip_addr}'/>" --live --config
  else
  ##done
  # !!!Arbitrary quantity of networks (up to 18) predefined (hardcoded) .100 IPs
  ARRAY=()
  for i in ${cn_net[@]}; do
    echo "net${i} is: $i"; ARRAY+=(10.${i}.101.100)
  done
  echo "nets are: ${cn_net[@]}";echo "IP(s) in nets are ${ARRAY[@]}"
    for ((ips = 0; ips < ${#cn_net[@]}; ips++)); do
      cmac=$(virsh domiflist ${node} | grep "${cn_net[ips]}" | awk '{print $5}')
      printf "%s is in %s\n" "${ARRAY[ips]}" "${cn_net[ips]}"
      echo "mac: $cmac"; echo "ip: ${ARRAY[ips]}"
      virsh net-update ${cn_net[ips]} add ip-dhcp-host \
          "<host mac='${cmac}' ip='${ARRAY[ips]}'/>" --live --config
    done
  fi
}
