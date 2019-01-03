#!/bin/bash
sudo apt-get remove docker docker-engine docker.io -y

sudo apt-get update

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-get update
apt install -y docker-ce=18.06.1~ce~3-0~ubuntu
#sudo apt-get install docker-ce -y
