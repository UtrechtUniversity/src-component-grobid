#!/bin/bash
set -euo pipefail

compose_file="$1"
compose_location="$( dirname -- "${BASH_SOURCE[0]}" )"

echo "Grobid Component: running init script for compose file $compose_file"

cat <<EOF > /etc/systemd/system/grobid.service
[Unit]
Description=Grobid Service
Requires=docker.service
After=docker.service
StartLimitIntervalSec=60

[Service]
WorkingDirectory=$compose_location
ExecStart=/usr/local/bin/docker-compose -f $compose_file up
ExecStop=/usr/local/bin/docker-compose -f $compose_file down
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable grobid.service

# Fix for oauth with reverse proxies at a subpath
sed -i 's/oauth2_callback&/oauth2_callback?rdpath=$request_uri\&/' /etc/nginx/app-location-conf.d/authentication.conf
sed -i 's/return 302 $scheme:\/\/$http_host\//return 302 $scheme:\/\/$http_host$arg_rdpath/' /etc/nginx/app-location-conf.d/authentication.conf

systemctl restart nginx
