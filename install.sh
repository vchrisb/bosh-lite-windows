#!/usr/bin/env bash

set -e

set -x # show the commands we are running

# installing required packages
sudo apt-get update
sudo apt-get -y install git unzip curl

# clone repositories
git clone https://github.com/cloudfoundry/bosh-lite.git ~/bosh-lite
git clone https://github.com/cloudfoundry/cf-release.git ~/cf-release
git clone https://github.com/cloudfoundry/diego-release.git ~/diego-release

# update the subprojects
~/cf-release/scripts/update
cd ~/diego-release && ./scripts/update

# install & configure rbenv
sudo apt-get install rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
rbenv install 2.4.0
rbenv global 2.4.0
source ~/.bashrc

#fix .gem permissions
sudo chown vagrant:vagrant ~/.gem

# install ruby dependencies
gem install bundler
bundle install --gemfile /home/vagrant/cf-release/Gemfile

# install spiff
wget -q https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.8/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
rm spiff_linux_amd64.zip
sudo mv spiff /usr/local/bin/

# modify provision_cf for in VM execution vs. Vagrant
sed -i.bak "s/ip=\$(get_ip_from_vagrant_ssh_config)/ip=\$(ifconfig | grep addr:192 | awk '{print \$2}' | cut -d: -f2)/g" ~/bosh-lite/bin/provision_cf

set +x # stop showing commands