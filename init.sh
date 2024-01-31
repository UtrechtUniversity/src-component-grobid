#!/bin/bash

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
