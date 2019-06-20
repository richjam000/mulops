docker volume create mulops_html
docker volume create mulops_cgi-bin
docker volume create mulops_logs
docker volume create mulops_conf
docker run -d --name=mulops --network=jamnet  --hostname=mulops \
--volume mulops_html:/var/www/html \
--volume mulops_cgi-bin:/var/www/cgi-bin \
--volume mulops_logs:/var/log/httpd \
--volume mulops_conf:/etc/httpd \
localhost:5000/scsuk.net/mulops:1.0
