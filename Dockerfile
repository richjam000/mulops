# I use: docker build -t localhost:5000/scsuk.net/mulops:1.0 https://gitlab.local/rich/mulops.git
FROM registry.access.redhat.com/ubi7-init:7.6-23
RUN yum -y install httpd perl
RUN systemctl enable httpd
COPY . /var/www/cgi-bin/mulops
RUN ln -s /usr/local/apache2/cgi-bin/mulops/catalog /usr/local/apache2/htdocs/mulops
RUN ln -s /var/www/cgi-bin/mulops/catalog /var/www/html
