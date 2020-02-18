#!/bin/bash
systemctl stop 5tonicmon.service
systemctl disable 5tonicmon.service
cd /opt/5tonic_mon
docker-compose down
rm -rf /opt/5tonic_mon
rm /etc/systemd/system/5tonicmon.service
systemctl daemon-reload

