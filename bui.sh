#!/usr/bin/env bash

set -e

set -x # show the commands we are running

# install golang		
cd /tmp		
wget -N -nv https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz		
sudo tar -C /usr/local -xzf go1.8.linux-amd64.tar.gz
mkdir -p ~/go/{bin,src,pkg}
mkdir ~/tmp
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
echo 'export PATH=$PATH:$(go env GOPATH)/bin' | sudo tee --append  /etc/profile.d/golang.sh
echo 'export GOPATH=$(go env GOPATH)' | sudo tee --append  /etc/profile.d/golang.sh

source /etc/profile.d/golang.sh

# install glide
curl https://glide.sh/get | sh

mkdir -p ~/go/src/github.com/cloudfoundry-community
git clone https://github.com/cloudfoundry-community/bui.git ~/go/src/github.com/cloudfoundry-community/bui
cd ~/go/src/github.com/cloudfoundry-community/bui
glide install -v
make

tee config.yml <<'HERE'
listen_addr: :9304
web_root: /home/vagrant/go/src/github.com/cloudfoundry-community/bui/ui
cookie_secret: my-secret-cookie
bosh_addr: https://192.168.50.4:25555
skip_ssl_validation: true
HERE

tee bui.sh <<'HERE'
#!/bin/bash
export BUI_HOME=/home/vagrant/go/src/github.com/cloudfoundry-community/bui
export BUI_CONFIG=/home/vagrant/go/src/github.com/cloudfoundry-community/bui/config.yml
 
case $1 in
  start)
    echo $$ > /var/vcap/sys/run/bui.pid;
    exec $BUI_HOME/bui -c $BUI_CONFIG
    ;;
  stop)  
    kill `cat /var/vcap/sys/run/bui.pid` ;;
  *)  
    echo "usage: bui {start|stop}" ;;
esac
exit 0
HERE

chmod 0775 bui.sh

sudo tee /var/vcap/monit/job/0007_bui.monitrc <<'HERE'
check process bui
  with pidfile /var/vcap/sys/run/bui.pid
  start program "/home/vagrant/go/src/github.com/cloudfoundry-community/bui/bui.sh start"
  stop program "/home/vagrant/go/src/github.com/cloudfoundry-community/bui/bui.sh stop"
  group vcap
  if failed host 127.0.0.1 port 9304 protocol HTTP then restart
HERE

#reload monit
sudo /var/vcap/bosh/bin/monit reload
sleep 3
sudo /var/vcap/bosh/bin/monit start bui
sleep 5

set +x # stop showing commands

# status of director services
sudo /var/vcap/bosh/bin/monit summary