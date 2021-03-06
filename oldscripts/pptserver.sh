#!/bin/bash

echo " ===> Installing curl wget git tmux"
apt-get update
apt-get install -y curl wget git tmux

echo " ===> Installing the Puppetlabs apt repo"
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

echo " ===> Installing puppetserver"
apt-get -y install puppetserver

echo " ===> Configuring puppetserver"
sed -i -e 's/JAVA_ARGS="-Xms2g -Xmx2g -XX:MaxPermSize=256m"/JAVA_ARGS="-Xms1g -Xmx1g -XX:MaxPermSize=256m"/' /etc/default/puppetserver

mkdir -p /etc/facter/facts.d

echo " ===> Configure Puppet"
sed -i '/templatedir/d' /etc/puppet/puppet.conf
puppet config set --section main parser future
puppet config set --section main evaluator current
puppet config set --section main ordering manifest

#echo " ===> Installing Librarian Puppet Simple"
#gem install librarian-puppet-simple

#echo " ===> Installing Modules"
#cd /etc/puppet/
#librarian-puppet install --puppetfile=/vagrant/support/puppet/Puppetfile
#librarian-puppet install --puppetfile=./puppetfile --path=/etc/puppet/modules

echo " ===> Configuring Hiera"
rm /etc/hiera.yaml
ln -s /etc/puppet/modules/site/ext/hiera.yaml /etc
ln -s /etc/puppet/modules/site/ext/hiera.yaml /etc/puppet
gem install deep_merge

echo " ===> Checking if SSL cert exists."
echo " ===> and generating one if it doesnt."
if [ ! -e "$(puppet config print hostcert)" ]; then
  puppet cert generate $(puppet config print certname)
fi

echo " ===> Installing PuppetDB"
apt-get -y install puppetdb
cd /root
echo include puppetdb > pdb.pp
echo include puppetdb::master::config >> pdb.pp
puppet apply --verbose pdb.pp
echo "===> sleep 5"
sleep 5
puppet apply --verbose pdb.pp
rm pdb.pp

echo " ===> Installing Puppet Master Role"
puppet apply --verbose /etc/puppet/modules/site/manifests/site.pp
puppet agent -t

