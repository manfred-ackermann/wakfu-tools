#!/bin/bash

me=$USER

if [[ $(whoami) = root ]]
then
  echo "Not to execute as root! Execute as user."
  exit 1
fi

if [[ "$OSTYPE" != "linux"* ]]
then
  echo "You have to execute on a linux os."
  exit 1
fi

sudo tee /etc/systemd/system/wakfu-stats.service <<EOSD
[Unit]
Description=Wakfu Stats

[Service]
User=$me
ExecStart=$(realpath $(dirname $0)/wakfu-stats.sh)

[Install]
WantedBy=multi-user.target
EOSD

sudo systemctl enable wakfu-stats.service
sudo systemctl start  wakfu-stats.service