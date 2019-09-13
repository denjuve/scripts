#!/bin/bash
exec 1>log.log 2>&1
user=ubuntu
nt=2            #nodes total:
export ver='=1.15.3-00'
#1.13.1-00   #kube version
node0='master'
node0_ip='192.168.122.166'
node1='node01'
node1_ip='192.168.122.60'
node2='node02'
node2_ip='192.168.122.25'

#nodes IP
sudo bash -c "cat << EOF >> /etc/hosts
$node0_ip $node0
$node1_ip $node1
$node2_ip $node2
EOF"

sudo swapoff -a
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-arptables=1
sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl net.bridge.bridge-nf-call-iptables=1

git clone https://github.com/denjuve/scripts.git 
bash scripts/docker_install.sh kub

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo bash -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

sudo apt-get update -y
sudo apt-get install -y kubelet${ver} kubectl${ver} kubeadm${ver}

########################
#scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $source $user@$host:$destination

cat <<EOF > kube_node_install.sh
#!/bin/bash
sudo swapoff -a
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-arptables=1
sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl net.bridge.bridge-nf-call-iptables=1
git clone https://github.com/denjuve/scripts.git 
sudo bash scripts/docker_install.sh kube
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet${ver} kubectl${ver} kubeadm${ver}
EOF

chmod +x kube_node_install.sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node1_ip} 'sudo bash -s' < kube_node_install.sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node2_ip} 'sudo bash -s' < kube_node_install.sh
########################

sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tee token.log
sudo cat token.log | grep -A 2 "kubeadm join " > token.get

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node1_ip} 'sudo bash -s' < token.get
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node2_ip} 'sudo bash -s' < token.get


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

if [ $nt == 1 ]
then
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node0_ip} 'token.get'
else
for h in node0-{0..$nt}
do
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@$h 'token.get'
done
fi

sudo kubectl apply -f kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml

sleep 25 && sudo kubectl get pods --all-namespaces
sleep 25 && sudo kubectl get nodes
