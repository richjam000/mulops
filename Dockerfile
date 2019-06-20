FROM localhost:5000/docker/httpd:2.4.39
COPY . /usr/local/apache2/cgi-bin
