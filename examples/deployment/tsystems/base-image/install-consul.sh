#!/bin/bash

dir=/opt/consul/agent
vsn=0.9.3
file=consul_${vsn}_linux_amd64.zip
url=https://releases.hashicorp.com/consul/$vsn/$file

set -ex
[ -d $dir ] && /bin/rm -rf $dir
mkdir -p $dir
cd $dir
[ -f $file ] || wget $url
unzip $file

chmod 755 $dir/consul

ln -s $dir/consul /usr/bin/

mkdir -p /etc/systemd/system/rabbitmq-server.service.d/
(
  echo '[Service]'
  echo 'LimitNOFILE=1048576'
) | tee /etc/systemd/system/rabbitmq-server.service.d/override.conf
systemctl daemon-reload
