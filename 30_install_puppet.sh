#!/bin/bash

echo -e "\n=======> Installing PuppetDB"
apt-get -y install puppetdb
puppet module install puppetlabs-puppetdb
cd /root
echo include puppetdb > pdb.pp
echo include puppetdb::master::config >> pdb.pp
puppet apply --verbose pdb.pp
echo "===> sleep 5"
sleep 5
puppet apply --verbose pdb.pp
rm pdb.pp

