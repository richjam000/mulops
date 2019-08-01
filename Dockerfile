FROM gitlab.scsuk.net:5005/scsuk/scs_httpd:1.0
COPY mulops /var/www/cgi-bin/mulops
COPY webfiles/mulops_http.conf /etc/httpd/conf.d/
COPY webfiles/index.html /var/www/html
RUN ln -s /var/www/cgi-bin/mulops/catalogs /var/www/html
