#!/bin/bash
exec 1>log.log 2>&1
user=ubuntu
nt=3            #nodes total:
ver='=1.15.3-00'
node1='node01'
node1_ip='192.168.122.4'
node2='node02'
node2_ip='192.168.122.14'
node3='node03'
node3_ip='192.168.122.57'

#nodes IP
sudo bash -c "cat << EOF >> /etc/hosts
$node1_ip $node1
$node2_ip $node2
$node3_ip $node3
EOF"

########################
cat <<EOF > kube_node_install.sh
#!/bin/bash
sudo swapoff -a
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-arptables=1
sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl net.bridge.bridge-nf-call-iptables=1
git clone https://github.com/denjuve/scripts.git 
if sudo docker version; then echo 'Docker installed'
else rm -rf /tmp/scripts-my; git clone https://github.com/denjuve/scripts.git /tmp/scripts-my
bash /tmp/scripts-my/docker_install.sh kube; fi
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet${ver} kubectl${ver} kubeadm${ver}
EOF

bash kube_node_install.sh
for ((i = 1; i <= nt; i++)); do
ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@node0${i} 'sudo bash -s' < kube_node_install.sh
done
########################

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 | tee token.log
sudo cat token.log | grep -A 2 "kubeadm join " > token.get

#ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node1_ip} 'sudo bash -s' < token.get
#ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node2_ip} 'sudo bash -s' < token.get

for ((i = 2; i <= nt; i++)); do
ssh -i key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@node0${i} 'sudo bash -s' < kube_node_install.sh
done

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#if [ $nt == 1 ]
#then
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${node0_ip} 'token.get'
#else
#for h in node0-{0..$nt}
#do
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@$h 'token.get'
#done
#fi

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

sleep 25 && sudo kubectl get pods --all-namespaces
sleep 25 && sudo kubectl get nodes
