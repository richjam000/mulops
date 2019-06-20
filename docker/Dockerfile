# Dockerfile  - for a mulops website, like www.mulops.com
# I use: docker build -t localhost:5000/scsuk.net/mulops:1.0 -f webfiles/Dockerfile https://gitlab.scsuk.net/rich/mulops.git#master
FROM localhost:5000/scsuk.net/scs_httpd:2.4.6-89
COPY . /var/www/cgi-bin/mulops
COPY webfiles/mulops_http.conf /etc/httpd/conf.d/
COPY webfiles/index.html /var/www/html
RUN ln -s /var/www/cgi-bin/mulops/catalogs /var/www/html
