#!/bin/bash

echo " " >> /etc/hosts
echo 127.0.0.1 $(hostname).cybera.ca $(hostname) >> /etc/hosts

apt-get install -y curl wget git ntp

wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

apt-get install -y puppetmaster-passenger puppet
