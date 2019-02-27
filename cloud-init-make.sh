#!/bin/bash
vm_os=ubuntu
centos
ubuntu #ubuntu or centos
STORAGE_DIR="/home/virt-vm-local"
image_dir="/home/virt-vm-local"
node=s01
ram=15000
cpu=2
IP_ADDR='192.168.122.100'
net_name='default'
net_bridge=virbr0

function update_public_network {
     # set static ip address for node    \/ change this
cmac=$(virsh domiflist ${node} | awk '/virbr0/ {print $5; exit}')
echo $cmac; echo $IP_ADDR
virsh net-update "${net_name}" add ip-dhcp-host \
    "<host mac='${cmac}' ip='${IP_ADDR}'/>" --live --config
}
#    "<host mac='${cmac}' name='${node}' ip='${IP_ADDR}'/>" --live --config


if [[ "$vm_os" == "ubuntu" ]]
then
base_image="https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img"
image1="xenial-server-cloudimg-amd64-disk1.img"
else
base_image="https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
image1="CentOS-7-x86_64-GenericCloud.qcow2"
fi

#function generate_ssh_key {
#  local mcp_ssh_key=$(basename "${SSH_KEY}")
#  local user=${USER}
#  if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != 'root' ]; then
#    user=${SUDO_USER}
#  fi
#
#  if [ -f "${SSH_KEY}" ]; then
#    cp "${SSH_KEY}" .
#    ssh-keygen -f "${mcp_ssh_key}" -y > "${mcp_ssh_key}.pub"
#  fi
#
#  [ -f "${mcp_ssh_key}" ] || ssh-keygen -f "${mcp_ssh_key}" -N ''
#  sudo install -D -o "${user}" -m 0600 "${mcp_ssh_key}" "${SSH_KEY}"
#SSH_KEY
#}


function prepare_vms {
  local base_image=$1; shift
  local image_dir=$1; shift
#?  local repos_pkgs_str=$1; shift # ^-sep list of repos, pkgs to install/rm
#  local vnodes=("$@")
  local image="$image1"
#"CentOS-7-x86_64-GenericCloud.qcow2"
#"xenial-server-cloudimg-amd64-disk1.img"
#  base_image_opnfv_fuel.img
  local vcp_image=${image%.*}_vcp.img
  local _o=${base_image/*\/}
#  local _h=$(echo "${repos_pkgs_str}.$(md5sum "${image_dir}/${_o}")" | \
#             md5sum | cut -c -8)
  local _tmp
#  cleanup_uefi
#  cleanup_vms

function get_base_image {
local base_image=$1
local image_dir=$2
#  mkdir -p "${image_dir}"
wget --progress=dot:giga -P "${image_dir}" -N "${base_image}"
}
      get_base_image "${base_image}" "${image_dir}"
#  IFS='^' read -r -a repos_pkgs <<< "${repos_pkgs_str}"
#  echo "[INFO] Lookup cache / build patched base image for fingerprint: ${_h}"
#  _tmp="${image%.*}.${_h}.img"
#  if [ "${image_dir}/${_tmp}" -ef "${image_dir}/${image}" ]; then
#    echo "[INFO] Patched base image found"
#  else
#    rm -f "${image_dir}/${image%.*}"*
#    if [[ ! "${repos_pkgs_str}" =~ ^\^+$ ]]; then
#      echo "[INFO] Patching base image ..."
#      cp "${image_dir}/${_o}" "${image_dir}/${_tmp}"
#      __kernel_modules "${image_dir}"
#      mount_image "${_tmp}" "${image_dir}"
#      apt_repos_pkgs_image "${repos_pkgs[@]:0:4}"
#      cleanup_mounts
#    else
#      echo "[INFO] No patching required, using vanilla base image"
#    ln -sf "${image_dir}/${_o}" "${image_dir}/${_tmp}"
#    fi
#    ln -sf "${image_dir}/${_tmp}" "${image_dir}/${image}"
#  fi

  # Create config ISO and resize OS disk image for each foundation node VM
#  for node in "${vnodes[@]}"; do
#    if [[ "${node}" =~ ^(cfg01|mas01) ]]; then
#      user_data='user-data.mcp.sh'
#    else
#      user_data='user-data.admin.sh'
#    fi
    ./create-config-drive.sh -k ~/.ssh/id_rsa.pub \
       -u "${user_data}" -h "${node}" "${image_dir}/${node}.iso"
    cp "${image_dir}/${image}" "${image_dir}/${node}.qcow2"
    qemu-img resize "${image_dir}/${node}.qcow2" 100G
#    # Prepare dedicated drive for cinder on cmp nodes
#    if [[ "${node}" =~ ^(cmp) ]]; then
#      qemu-img create "${image_dir}/${node}_storage.qcow2" 100G
#    fi
#  done

#  # VCP VMs base image specific changes
#  if [[ ! "${repos_pkgs_str}" =~ \^{3}$ ]] && [ -n "${repos_pkgs[*]:4}" ]; then
#    echo "[INFO] Lookup cache / build patched VCP image for md5sum: ${_h}"
#    _tmp="${vcp_image%.*}.${_h}.img"
#    if [ "${image_dir}/${_tmp}" -ef "${image_dir}/${vcp_image}" ]; then
#      echo "[INFO] Patched VCP image found"
#    else
#      echo "[INFO] Patching VCP image ..."
#      cp "${image_dir}/${image}" "${image_dir}/${_tmp}"
#      __kernel_modules "${image_dir}"
#      mount_image "${_tmp}" "${image_dir}"
#      apt_repos_pkgs_image "${repos_pkgs[@]:4:4}"
#      cleanup_mounts
#      ln -sf "${image_dir}/${_tmp}" "${image_dir}/${vcp_image}"
#    fi
#  fi
}

    prepare_vms "${base_image}" "${STORAGE_DIR}" "${virtual_repos_pkgs}" \
      "${virtual_nodes[@]}"

#?    create_networks "${OPNFV_BRIDGES[@]}"
#    do_sysctl_cfg

function create_vms {
  local image_dir=$1; shift
#  # vnode data should be serialized with the following format:
#  # '<name0>,<ram0>,<vcpu0>|<name1>,<ram1>,<vcpu1>[...]'
#  IFS='|' read -r -a vnodes <<< "$1"; shift

#  # AArch64: prepare arch specific arguments
#  local virt_extra_args=""
#  if [ "$(uname -i)" = "aarch64" ]; then
#    # No Cirrus VGA on AArch64, use virtio instead
#    virt_extra_args="$virt_extra_args --video=virtio"
#  fi

#  # create vms with specified options
#  for serialized_vnode_data in "${vnodes[@]}"; do
#    IFS=',' read -r -a vnode_data <<< "${serialized_vnode_data}"

    # prepare network args
#?    local vnode_networks=("$@")
##    if [[ "${vnode_data[0]}" =~ ^(cfg01|mas01) ]]; then
##      net_args=" --network network=mcpcontrol,model=virtio"
##      # 3rd interface gets connected to PXE/Admin Bridge (cfg01, mas01)
##      vnode_networks[2]="${vnode_networks[0]}"
##    else
#      net_args=" --network bridge=${vnode_networks[0]},model=virtio"
##    fi
#    for net in "${vnode_networks[@]:1}"; do
#      net_args="${net_args} --network bridge=${net},model=virtio"
#    done

net_args="--network bridge=${net_bridge},model=virtio"
# --network bridge=ub16,model=virtio"
#--network bridge=ub16,model=virtio"
#--network bridge=virbr0,model=virtio --network bridge=virbr0,model=virtio --network bridge=mngbr0,model=virtio"

#    # dedicated storage drive for cinder on cmp nodes
#    virt_extra_storage=
#    if [[ "${vnode_data[0]}" =~ ^(cmp) ]]; then
#      virt_extra_storage="--disk path=${image_dir}/mcp_${vnode_data[0]}_storage.qcow2,format=qcow2,bus=virtio,cache=none,io=native"
#    fi

    # shellcheck disable=SC2086
    virt-install --name "${node}" \
    --ram "${ram}" --vcpus "${cpu}" \
    --cpu host-passthrough --accelerate ${net_args} \
    --disk path="${image_dir}/${node}.qcow2",format=qcow2,bus=virtio,cache=none,io=native \
    --os-type linux --os-variant none \
    --boot hd --vnc --console pty --autostart --noreboot \
    --disk path="${image_dir}/${node}.iso",device=cdrom \
    --noautoconsole \
    ${virt_extra_args}
#  done
}

    create_vms "${STORAGE_DIR}" "${virtual_nodes_data}" "${OPNFV_BRIDGES[@]}"

    update_public_network

    virsh start "${node}"
