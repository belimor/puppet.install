#!/bin/bash

myhostname = $( facter fqdn )

echo -e "\n=======> Configure Puppet"
# templatedir - depricated
sed -i '/templatedir/d' /etc/puppet/puppet.conf
puppet config set --section main parser future
puppet config set --section main evaluator current
puppet config set --section main ordering manifest
puppet config set --section main server $myhostname

echo -e "\n=======> Setting up Directory Environments"
PROD="/etc/puppet"
SITE="/etc/puppet/modules/site"
mkdir -p /etc/puppet/modules/site
mkdir -p /etc/puppet/modules/site/{files,templates,manifests,tests,ext,data}
mkdir -p /etc/puppet/modules/site/manifests/{roles,profiles}

echo -e "\n=======> Configuring Hiera"
echo "Configuring Hiera"
cat > /etc/puppet/modules/site/ext/hiera.yaml <<EOF
---
:backends:
  - yaml
:hierarchy:
  - "nodes/%{::fqdn}"
  - "osfamily/%{::osfamily}"
  - "locations/%{::location}"
  - "common"
:yaml:
  :datadir: "/etc/puppet/modules/site/data"
EOF

mkdir $SITE/data/nodes
mkdir $SITE/data/locations

rm /etc/hiera.yaml
ln -s /etc/puppet/modules/site/ext/hiera.yaml /etc
ln -s /etc/puppet/modules/site/ext/hiera.yaml /etc/puppet
gem install deep_merge

echo -e "\n=======> Checking if SSL cert exists"
echo "=======> and generating one if it doesnt"
if [ ! -e "$(puppet config print hostcert)" ]; then
  puppet cert generate $(puppet config print certname)
fi

service puppetserver start
puppet agent -t
service puppetserver status
service puppetserver stop
