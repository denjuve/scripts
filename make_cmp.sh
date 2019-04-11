#!/bin/bash
$curent_ip="10.5.1.99"
$current_tenant_ip="10.6.1.99"

ctl01_ip="10.5.1.95"
cmp01_ip="10.5.1.97"
cmp02_ip="10.5.1.96"
cmp03_ip="10.5.1.98"
cmp04_ip="10.5.1.99"
cmp05_ip="10.5.1.93"
cmp06_ip="10.5.1.92"

ctl01_name="ctl01"
cmp01_name="cmp01"
cmp02_name="cmp02"
cmp03_name="cmp03"
cmp04_name="cmp04"
cmp05_name="cmp05"
cmp06_name="cmp06"

echo "$ctl01_ip       $ctl01_name" >> /etc/hosts
echo "$cmp01_ip       $cmp01_name" >> /etc/hosts
echo "$cmp02_ip       $cmp02_name" >> /etc/hosts
echo "$cmp03_ip       $cmp03_name" >> /etc/hosts
echo "$cmp04_ip       $cmp04_name" >> /etc/hosts
echo "$cmp05_ip       $cmp05_name" >> /etc/hosts
echo "$cmp06_ip       $cmp06_name" >> /etc/hosts


yum update -y
yum upgrade -y
yum install -y vim telnet mtr net-tools tcpdump git wget curl bridge-utils
brctl addbr br-ex
brctl addbr br-tun


#cat /etc/chrony.conf | grep -v "#" | grep -v -e '^$'
cat <<EOF > /etc/chrony.conf
server ctl01 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 10.5.0.0/16
logdir /var/log/chrony
EOF

systemctl enable chronyd.service
systemctl restart chronyd.service

#make if for source ctl01
if chronyc sources | grep ctl01
then
echo "chrony ok"
else
echo "chrony fails"
exit 1
fi


yum install centos-release-openstack-rocky -y
yum upgrade -y && yum install openstack-selinux -y
yum install openstack-nova-compute -y



# nova.conf
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:d3aae2d875a891cc95b4@ctl01
my_ip = $curent_ip
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[api]
auth_strategy = keystone
[glance]
api_servers = http://ctl01:9292
[keystone_authtoken]
auth_url = http://ctl01:5000/v3
memcached_servers = ctl01:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = 4e5a2038e3c3ca6adece
[libvirt]
virt_type = kvm
[neutron]
url = http://ctl01:9696
auth_url = http://ctl01:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = e6440914313ec75f422a
service_metadata_proxy = true
metadata_proxy_shared_secret = 487d9608be0974fea873
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://ctl01:5000/v3
username = placement
password = d2b6e0fd9c8c2b2af942
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $curent_ip
novncproxy_base_url = http://10.5.1.95:6080/vnc_auto.html
EOF

systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service

yum install openstack-neutron-linuxbridge ebtables ipset -y

cat<<EOF > /etc/neutron/neutron.conf
[DEFAULT]
transport_url = rabbit://openstack:d3aae2d875a891cc95b4@ctl01
auth_strategy = keystone
core_plugin = ml2
[keystone_authtoken]
www_authenticate_uri = http://ctl01:5000
auth_url = http://ctl01:5000
memcached_servers = ctl01:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = e6440914313ec75f422a
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
EOF


cat<<EOF > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[DEFAULT]
[agent]
[linux_bridge]
physical_interface_mappings = provider:qbr-port
integration_bridge = br-int
tunnel_bridge = br-tun
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
enable_security_group = True
[vxlan]
enable_vxlan = true
local_ip = $current_tenant_ip
l2_population = true
EOF


modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables

systemctl enable neutron-linuxbridge-agent.service
systemctl restart neutron-linuxbridge-agent.service



ip link add dev br-ex-port type veth peer name qbr-port
ip li set dev br-ex-port up
ip li set dev qbr-port up
brctl addif br-ex br-ex-port
