docker volume create mulops_htdocs
docker volume create mulops_cgi-bin
docker volume create mulops_logs
docker volume create mulops_conf
docker run -d --name=mulops --network=jamnet  --hostname=mulops \
--volume mulops_htdocs:/usr/local/apache2/htdocs \
--volume mulops_cgi-bin:/usr/local/apache2/cgi-bin \
--volume mulops_logs:/usr/local/apache2/logs \
--volume mulops_conf:/usr/local/apache2/conf \
localhost:5000/scsuk.net/mulops
