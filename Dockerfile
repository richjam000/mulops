FROM localhost:5000/docker/httpd:2.4.39
COPY . /usr/local/apache2/cgi-bin
RUN cat <<EOT >FRED
<meta http-equiv="refresh" content="0; URL='http://www.{whatever}.com/cgi-bin/mulops/bin/mulops.cgi'" />
EOT
