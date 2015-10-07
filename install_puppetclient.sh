#!/bin/bash

echo -e "\n=======> Installing the Puppetlabs apt repo"
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

#apt-get install -y puppet=3.7.5-1puppetlabs1
apt-get install -y puppet
