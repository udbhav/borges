FROM ubuntu
RUN mkdir /code
ADD . /root/borges-bootstrap/
WORKDIR /root/borges-bootstrap
RUN ./provision.sh