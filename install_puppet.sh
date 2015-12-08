#!/bin/bash

echo -e "\n=======> Installing curl wget git tmux"
apt-get update
apt-get install -y curl wget git tmux tree

echo -e "\n=======> Enabling security updates"
sudo apt-get install -y unattended-upgrades
echo """
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
""" | tee /etc/apt/apt.conf.d/20auto-upgrades

echo -e "\n=======> Check your /etc/hosts"
cat /etc/hosts

echo -e "\n=======> Installing the Puppetlabs apt repo"
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

echo -e "\n=======> Installing puppetserver"
apt-get -y install puppetserver

echo -e "\n=======> Configuring JAVA puppetserver"
sed -i -e 's/JAVA_ARGS="-Xms2g -Xmx2g -XX:MaxPermSize=256m"/JAVA_ARGS="-Xms1g -Xmx1g -XX:MaxPermSize=256m"/' /etc/default/puppetserver

myhostname=$( facter fqdn )

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
  - "operatingsystem/%{::operatingsystem}_%{lsbmajdistrelease}"
  - "locations/%{::location}"
  - "common"
:yaml:
  :datadir: "/etc/puppet/modules/site/data"
:merge_behavior: deeper
EOF

mkdir $SITE/data/nodes
mkdir $SITE/data/locations
mkdir $SITE/data/operatingsystem
mkdir $SITE/data/osfamily

echo "---" > $SITE/data/common.yaml
echo "---" > $SITE/data/operatingsystem/Ubuntu_14.04.yaml

rm /etc/hiera.yaml
ln -s /etc/puppet/modules/site/ext/hiera.yaml /etc
ln -s /etc/puppet/modules/site/ext/hiera.yaml /etc/puppet
gem install deep_merge

echo -e "\n=======> Checking if SSL cert exists"
echo "=======> and generating one if it doesnt"
if [ ! -e "$(puppet config print hostcert)" ]; then
  puppet cert generate $(puppet config print certname)
fi

echo ""
echo "=======> Starting puppet server"
service puppetserver start
puppet agent --enable
puppet agent -t
service puppetserver status
sleep 5
tail /var/log/puppetserver/puppetserver.log
service puppetserver stop

echo ""
echo "=======> Installing Puppet-Lint"
gem install puppet-lint

myhostname=$( facter fqdn )
puppetdbpwd="password"

echo ""
echo "=======> Installing PuppetDB"
apt-get -y install puppetdb postgresql puppetdb-terminus postgresql-contrib

sudo -u postgres bash <<EOF
createuser -DRS puppetdb 
psql -c "ALTER USER puppetdb WITH PASSWORD '${puppetdbpwd}';"
createdb -E UTF8 -O puppetdb puppetdb
psql puppetdb -c 'create extension pg_trgm'
EOF

service postgresql restart

cat > /etc/puppetdb/conf.d/database.ini <<EOF
[database]
classname = org.postgresql.Driver
subprotocol = postgresql
subname = //localhost:5432/puppetdb
username = puppetdb
password = $puppetdbpwd
log-slow-statements = 10
EOF

cat > /etc/puppetdb/conf.d/config.ini <<EOF
[global]
vardir = /var/lib/puppetdb
logging-config = /etc/puppetdb/logback.xml

[command-processing]
store-usage = 10240
temp-usage = 5120
EOF

cat > /etc/puppet/puppetdb.conf <<EOF
[main]
server = $myhostname
port = 8081
EOF

puppet config set --section main storeconfigs true
puppet config set --section main storeconfigs_backend puppetdb
puppet config set --section main reports store,puppetdb

cat > /etc/puppet/routes.yaml <<EOF
---
master:
  facts:
    terminus: puppetdb
    cache: yaml
EOF

chown -R puppet:puppet $(puppet config print confdir)
chown -R root:puppet /etc/puppet/modules/site/data
#chmod -R 0640 /etc/puppet/modules/site/data

echo ""
echo "=======> Restarting puppet server"
service puppetdb restart
sleep 60
tail /var/log/puppetdb/puppetdb.log
service puppetserver restart
sleep 60
tail /var/log/puppetserver/puppetserver.log
puppet agent --enable
puppet agent -t

