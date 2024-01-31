#!/bin/bash

compose_location="$( dirname -- "${BASH_SOURCE[0]}" )/docker-compose.yml"

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

cat << EOF > /etc/nginx/app-location-conf.d/grobid.conf
location /grobid/ {
    proxy_read_timeout  90s;
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    send_timeout 300;
    client_max_body_size 100M;

    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header Host \$host;
    proxy_pass http://localhost:8070/;
}
EOF

systemctl restart nginx
