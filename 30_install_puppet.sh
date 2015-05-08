#!/bin/bash

myhostname = $( facter fqdn )
puppetdbpwd = "password"

echo -e "\n=======> Installing PuppetDB"
apt-get -y install puppetdb postgresql puppetdb-terminus postgresql-contrib

sudo -u postgres <<EOF
createuser -DRSP puppetdb -W ${pupptdbpwd}
createdb -E UTF8 -O puppetdb puppetdb
psql puppetdb -c 'create extension pg_trgm'
EOF

service postgresql restart

cat /etc/puppetdb/conf.d/database.ini <<EOF
[database]
classname = org.postgresql.Driver
subprotocol = postgresql
subname = //localhost:5432/puppetdb
username = puppetdb
password = $puppetdbpwd
log-slow-statements = 10
EOF

cat /etc/puppetdb/conf.d/config.ini << EOF
[global]
vardir = /var/lib/puppetdb
logging-config = /etc/puppetdb/logback.xml

[command-processing]
store-usage = 10240
temp-usage = 5120
EOF

cat /etc/puppet/puppetdb.conf <<EOF
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

chown -R puppet:puppet `puppet config print confdir`

service puppetdb restart
service puppetserever restart
puppet agent -t

