#!/bin/bash

echo " " >> /etc/hosts
echo 127.0.0.1 $(hostname).cybera.ca $(hostname) >> /etc/hosts

apt-get install -y curl wget git ntp

wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

apt-get install -y puppetmaster 

echo "========> Initial changes to puppet.conf"
pptserver=$(facter fqdn)
sed -i '/templatedir/d' /etc/puppet/puppet.conf
puppet config set --section main parser future
puppet config set --section main evaluator current
puppet config set --section main ordering manifest
puppet config set --section main server $pptserver

puppet master --verbose & 
mypid=$!
sleep 3
kill $mypid

mkdir /etc/puppet/modules/site
mkdir -p /etc/puppet/modules/site/{files,templates,manifests,ext,data}
mkdir -p /etc/puppet/modules/site/manifests/{roles,profiles}

cat > /etc/puppet/modules/site/manifests/roles/base.pp <<EOF
class site::roles::base {
}
EOF

cat > /etc/puppet/modules/site/ext/site.pp <<EOF
node base {
  include site::roles::base
}
node '$(hostname)' {
  include site::roles::base
}
EOF

ln -s /etc/puppet/modules/site/ext/site.pp /etc/puppet/manifests/

echo "===> puppet apply --verbose /etc/puppet/manifests/site.pp"
puppet apply --verbose /etc/puppet/manifests/site.pp
