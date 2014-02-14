#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

SUDO=false
BARE=false

wget https://git.openstack.org/cgit/openstack-infra/config/plain/install_puppet.sh
sudo bash -xe install_puppet.sh
sudo git clone https://review.openstack.org/p/openstack-infra/config.git \
    /root/config
sudo sed -i "s/      privileges => \[.*\],/      privileges => \['all'\],/g" /root/config/modules/jenkins/manifests/slave.pp
sudo /bin/bash /root/config/install_modules.sh

if [ -z "$NODEPOOL_SSH_KEY" ] ; then
    sudo puppet apply --modulepath=/root/config/modules:/etc/puppet/modules \
        -e "class {'openstack_project::single_use_slave': sudo => $SUDO, bare => $BARE, }"
else
    sudo puppet apply --modulepath=/root/config/modules:/etc/puppet/modules \
        -e "class {'openstack_project::single_use_slave': install_users => false, sudo => $SUDO, bare => $BARE, ssh_key => '$NODEPOOL_SSH_KEY', }"
fi

mysql -uopenstack_citest -popenstack_citest -e "CREATE USER 'savanna-citest' IDENTIFIED BY 'savanna-citest'"
mysql -uopenstack_citest -popenstack_citest -e "GRANT ALL PRIVILEGES ON *.* TO 'savanna-citest'@localhost IDENTIFIED BY 'savanna-citest'"

sudo mkdir -p /opt/git
