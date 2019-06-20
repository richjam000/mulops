# I use: docker build -t localhost:5000/scsuk.net/mulops:1.0 https://gitlab.local/rich/mulops.git
FROM localhost:5000/docker/httpd:2.4.39
COPY . /usr/local/apache2/cgi-bin
RUN ln -s /usr/local/apache2/cgi-bin/mulops/catalog /usr/local/apache2/htdocs
