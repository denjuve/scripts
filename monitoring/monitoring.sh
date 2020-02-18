#!/bin/bash
mkdir -p /opt/5tonic_mon/{prometheus,grafana}
mkdir -p /opt/5tonic_mon/prometheus/{conf,data}
chown 65534:65534 /opt/5tonic_mon/prometheus/data

cat << EOF > /opt/5tonic_mon/docker-compose.yml
version: "3"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: 5tonic_prometheus
    volumes:
      - /opt/5tonic_mon/prometheus/conf:/etc/prometheus
      - /opt/5tonic_mon/prometheus/data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"

  mon_grafana:
    container_name: 5tonic_grafana
    ports:
      - "3000:3000"
    volumes:
    - /opt/5tonic_mon/grafana/grafana.ini:/etc/grafana/grafana.ini
    - /opt/5tonic_mon/grafana/datasource.yaml:/etc/grafana/provisioning/datasources/datasource.yaml
    - /opt/5tonic_mon/grafana/dashboard.yaml:/etc/grafana/provisioning/dashboards/dashboard.yaml
    - /opt/5tonic_mon/grafana/dashb.json:/var/lib/grafana/dashboards/dashb.json
#/etc/grafana/provisioning/dashboards/dashboard
    image: grafana/grafana
    environment:
#      - GF_SECURITY_ADMIN_PASSWORD=admin
#      - GF_USERS_ALLOW_SIGN_UP=false
#      - GF_SERVER_DOMAIN=myrul.com
#      - GF_SMTP_ENABLED=true
#      - GF_SMTP_HOST=smtp.gmail.com:587
#      - GF_SMTP_USER=myadrress@gmail.com
#      - GF_SMTP_PASSWORD=mypassword
#      - GF_SMTP_FROM_ADDRESS=myaddress@gmail.com
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel

#networks:
#  default:
#    external:
#      name: 5tonic_mon
EOF

cat << EOF > /etc/systemd/system/5tonicmon.service
[Unit]
Description=5tonic monitoring docker container
After=docker.service
BindsTo=docker.service

[Service]
Restart=always
WorkingDirectory=/opt/5tonic_mon/grafana
# Ubuntu
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
# CentOS
#ExecStart=/usr/bin/docker-compose up
#ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /opt/5tonic_mon/prometheus/conf/prometheus.yml
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

cat << EOF > /opt/5tonic_mon/grafana/datasource.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://5tonic_prometheus:9090
EOF

cp grafana.ini /opt/5tonic_mon/grafana/grafana.ini
cp dashb.json /opt/5tonic_mon/grafana/dashb.json

cat << EOF > /opt/5tonic_mon/grafana/dashboard.yaml
apiVersion: 1
providers:
- name: 'default'       # name of this dashboard configuration (not dashboard itself)
  org_id: 1             # id of the org to hold the dashboard
  folder: ''            # name of the folder to put the dashboard (http://docs.grafana.org/v5.0/reference/dashboard_folders/)
  type: 'file'          # type of dashboard description (json files)
  options:
    folder: /var/lib/grafana/dashboards
EOF

sudo systemctl daemon-reload
sudo systemctl enable 5tonicmon
sudo systemctl start 5tonicmon
