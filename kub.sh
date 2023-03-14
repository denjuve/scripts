#!/bin/bash
#exec 1>log.log 2>&1
user=ubuntu
nt=3            #nodes total:
ver='=1.15.3-00'

arr_na=()
arr_ip=()

for ((i = 1; i <=$nt; i++)); do
arr_na+=(node$[i])
echo "${arr_na[i]}" > /tmp/vms_kub"${arr_na[@]}" ######## for cleaning ############
arr_ip+=(10.77.101.1${i})
done

for ((n_c = 0; n_c < nt; n_c++)); do
bash cloud-init-make.sh2 -n "${arr_na[n_c]}" -r 15000 -c 2 -i "${arr_ip[n_c]}"
done

for ((pt = 0; pt < nt; pt++)); do
until ping -c 2 "${arr_ip[pt]}"; do
echo "."
done
done

##########################
cat <<EOF > kube_node_install.sh
#!/bin/bash
#nodes IP
#sudo bash -c "cat << EOF >> /etc/hosts
#$ip_node1 $node1
#$ip_node2 $node2
#$ip_node3 $node3
#EOF"
sudo swapoff -a && sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo modprobe br_netfilter
echo br_netfilter >> /etc/modules

echo "net.bridge.bridge-nf-call-arptables = 1"  >> /etc/sysctl.conf 
echo "net.bridge.bridge-nf-call-ip6tables = 1"  >> /etc/sysctl.conf 
echo "net.bridge.bridge-nf-call-iptables = 1"  >> /etc/sysctl.conf 
echo "net.ipv4.ip_forward = 1"  >> /etc/sysctl.conf 
sudo sysctl -p /etc/sysctl.conf 

#git clone https://github.com/denjuve/scripts.git 
if sudo docker version; then echo 'Docker installed'
else rm -rf /tmp/scripts-my; git clone https://github.com/denjuve/scripts.git /tmp/scripts-my
bash /tmp/scripts-my/docker_install.sh kube; fi
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet${ver} kubectl${ver} kubeadm${ver}
EOF



#bash kube_node_install.sh
for ((j = 0; j < nt; j++)); do
ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[j]}" 'sudo bash -s' < kube_node_install.sh
done
#########################

ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[0]}" 'sudo kubeadm init --pod-network-cidr=10.244.0.0/16 | tee token.log'
ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[0]}" 'cat token.log | grep -A 2 "kubeadm join " | tee token.get'
scp -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[0]}":~/token.get token.get

for ((j = 1; j < nt; j++)); do
ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[j]}" 'sudo bash -s' < token.get
done

ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[0]}" 'mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config'
#

ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[0]}" 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml'
#
ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@"${arr_ip[0]}" 'sleep 25 && sudo kubectl get pods --all-namespaces; sleep 25 && sudo kubectl get nodes'
