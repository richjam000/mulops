#!/bin/bash

docker run -d --name=mulops --network=jamnet --hostname=mulops --restart=always \
--volume mulops_html:/var/www/html \
--volume mulops_cgi-bin:/var/www/cgi-bin \
--volume mulops_logs:/var/log/httpd \
--volume mulops_conf:/etc/httpd \
localhost:5000/scsuk.net/mulops:1.0
