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
sed -i 's/return 302 $scheme:\/\/$http_host\//return 302 $scheme:\/\/$http_host$arg_rdpath/' /etc/nginx/app-location-conf.d/authentication.conf

VHOST_TEMPLATE="
location %s {
    proxy_read_timeout  90s;
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    send_timeout 300;
    client_max_body_size 100M;

    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header Host \$host;
    proxy_pass %s;
}
"

printf "$VHOST_TEMPLATE" "/grobid/" "http://localhost:8070/" > /etc/nginx/app-location-conf.d/grobid.conf
printf "$VHOST_TEMPLATE" "/datastet/" "http://localhost:8060" > /etc/nginx/app-location-conf.d/grobid.conf
printf "$VHOST_TEMPLATE" "/softcite/" "http://localhost:8061" > /etc/nginx/app-location-conf.d/grobid.conf

systemctl restart nginx
