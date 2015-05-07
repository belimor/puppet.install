#!/bin/bash

echo -e "\n=======> Installing the Puppetlabs apt repo"
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

echo -e "\n=======> Installing puppetserver"
apt-get -y install puppetserver

echo -e "\n=======> Configuring JAVA puppetserver"
sed -i -e 's/JAVA_ARGS="-Xms2g -Xmx2g -XX:MaxPermSize=256m"/JAVA_ARGS="-Xms1g -Xmx1g -XX:MaxPermSize=256m"/' /etc/default/puppetserver

