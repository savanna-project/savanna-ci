#!/bin/bash

BUILD_ID=dontKill

sudo pip install tox
mkdir /tmp/cache

export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "[DEFAULT]
os_auth_host=172.18.168.5
os_admin_username=admin
os_admin_password=swordfish
os_admin_tenant_name=admin
plugins=vanilla
[cluster_node]
[sqlalchemy]
[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider" >> etc/savanna/savanna.conf

echo "
[global] 
timeout = 60
index-url = http://savanna-ci.vm.mirantis.net/pypi/savanna/
extra-index-url = https://pypi.python.org/simple/
download-cache = /tmp/cache
[install]
use-mirrors = true
find-links = http://savanna-ci.vm.mirantis.net:8181/simple/
" > ~/.pip/pip.conf
screen -dmS savanna-api tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file log.txt
