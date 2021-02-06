#!/bin/bash

if [[ $(whoami) != root ]]
then
  echo "You have to execute as root or with sudo."
  exit 1
fi

if [[ "$OSTYPE" != "linux"* ]]
then
  echo "You have to execute on a linux system."
  exit 1
fi

cat > /etc/systemd/system/wakfu-stats.service <<EOSD
[Unit]
Description=Wakfu Stats

[Service]
User=$USER
ExecStart=$(realpath $(dirname $0)/wakfu-stats.sh)

[Install]
WantedBy=multi-user.target
EOSD

systemctl enable wakfu-stats.service
systemctl start  wakfu-stats.service