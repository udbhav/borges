#!/bin/bash

# install curl for chefdk
apt-get -y update
apt-get -y install wget

# chefdk
cd /home && wget --quiet https://packages.chef.io/files/stable/chefdk/1.1.16/ubuntu/16.04/chefdk_1.1.16-1_amd64.deb
dpkg -i /home/chefdk_1.1.16-1_amd64.deb

mkdir -p /root/local_mode_repo/cookbooks
cp -rf /root/borges-bootstrap/data_bags /root/local_mode_repo/
cd /root/borges-bootstrap && berks vendor /root/local_mode_repo/cookbooks
cd /root/local_mode_repo && chef-client -z -o borges
rm -rf /root/borges-bootstrap
