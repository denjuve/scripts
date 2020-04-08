#!/bin/bash

if [  -n "$(uname -rv | grep -i ubuntu)" ]; then
sudo apt-get remove docker docker-engine docker.io -y
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"


sudo apt-get update
#18.06.1~ce~3-0~ubuntu
if [ -z "$1" ]
then
sudo apt-get install -y docker-ce
else
sudo apt install -y docker-ce=18.06.2~ce~3-0~ubuntu
#17.03.2~ce-0~ubuntu-xenial
fi


else
sudo yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
fi
