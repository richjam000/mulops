FROM localhost:5000/scsuk.net/scs_httpd:1.0
COPY . /var/www/cgi-bin/mulops
COPY webfiles/mulops_http.conf /etc/httpd/conf.d/
COPY webfiles/index.html /var/www/html
RUN ln -s /var/www/cgi-bin/mulops/catalogs /var/www/html
