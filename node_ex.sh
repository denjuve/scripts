#!/bin/bash
sudo useradd node_exporter -s /sbin/nologin
wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar xvfz node_exporter-0.18.1.linux-amd64.tar.gz
cp  node_exporter-0.18.1.linux-amd64/node_exporter /usr/sbin/

cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
EnvironmentFile=/etc/sysconfig/node_exporter
ExecStart=/usr/sbin/node_exporter $OPTIONS

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/sysconfig

cat << EOF > /etc/sysconfig/node_exporter
OPTIONS="--collector.textfile.directory /var/lib/node_exporter/textfile_collector"
EOF



sudo systemctl daemon-reload

sudo systemctl enable node_exporter

sudo systemctl start node_exporter
