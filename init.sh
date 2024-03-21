#!/bin/bash

compose_location="$( dirname -- "${BASH_SOURCE[0]}" )"

cat <<EOF > /etc/systemd/system/grobid.service
[Unit]
Description=Grobid Service
Requires=docker.service
After=docker.service
StartLimitIntervalSec=60

[Service]
WorkingDirectory=$compose_location
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable grobid.service

# Fix for oauth with reverse proxies at a subpath
sed -i 's/oauth2_callback&/oauth2_callback?rdpath=$request_uri\&/' /etc/nginx/app-location-conf.d/authentication.conf
