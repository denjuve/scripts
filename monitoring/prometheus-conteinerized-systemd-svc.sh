#!/bin/bash

mkdir -p /opt/prometheus/{conf,data}
chown 65534:65534 /opt/prometheus/data

cat << EOF > /opt/prometheus/conf/prometheus.yml
scrape_configs:
  - job_name: 'vim2'
    static_configs:
      - targets: ['10.5.1.50:9100','10.5.1.49:9100']

  - job_name: 'vim1'
    static_configs:
      - targets: ['10.5.1.95:9100','10.5.1.96:9100','10.5.1.97:9100','10.5.1.98:9100','10.5.1.99:9100','10.5.1.92:9100','10.5.1.93:9100']

  - job_name: 'ehealth: devstack+ovs+windows'
    static_configs:
      - targets: ['10.5.1.124:9100','10.5.1.130:9100']

  - job_name: '5tonic_HW'
    static_configs:
      - targets: ['10.5.1.10:9100','10.5.1.11:9100','10.5.1.12:9100','10.5.1.14:9100','10.5.1.19:9100','10.5.1.20:9100','10.5.1.253:9100','10.5.1.254:9100']
EOF


cat << EOF > /opt/prometheus/docker-compose.yml
version: "3"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: 5tonic_mon
    volumes:
      - /opt/prometheus/conf:/etc/prometheus
      - /opt/prometheus/data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
EOF

cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus monitoring docker container
After=docker.service
BindsTo=docker.service

[Service]
Restart=always
WorkingDirectory=/opt/prometheus/
# Ubuntu
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
