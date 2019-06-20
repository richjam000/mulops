# Dockerfile  - for a mulops website, like www.mulops.com
# I use: docker build -t localhost:5000/scsuk.net/mulops:1.0 -f webfiles/Dockerfile https://gitlab.scsuk.net/rich/mulops.git#master
FROM registry.access.redhat.com/ubi7-init:7.6-23
RUN yum -y install httpd perl
RUN systemctl enable httpd
COPY . /var/www/cgi-bin/mulops
COPY webfiles/mulops_http.conf /etc/httpd/conf.d/
COPY webfiles/index.html /var/www/html
RUN ln -s /var/www/cgi-bin/mulops/catalogs /var/www/html
