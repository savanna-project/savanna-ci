#!/bin/bash

# Next instcruction includes file "params", which contains values for savanna_cd.conf. For example:
# #!/bin/bash
# os_auth_host=127.0.0.1
# os_auth_port=35357
# os_admin_password=swordfish

. $WORKSPACE/params

cd $WORKSPACE

BUILD_ID=dontKill
#echo -e "[global] 
#timeout = 60
#index-url = http://savanna-ci.vm.mirantis.net/pypi/savanna/
#extra-index-url = https://pypi.python.org/simple/
#download-cache = /home/ubuntu/.pip/cache/
#[install]
#use-mirrors = true
#find-links = http://savanna-ci.vm.mirantis.net:8181/simple/" > ~/.pip/pip.conf

cd $WORKSPACE/savanna

git fetch origin $GERRIT_BRANCH
git rebase origin/$GERRIT_BRANCH

if [ $? != 0 ]
then
    git rebase --abort
    echo "ERROR. git rebase failed"
    exit 1
fi

os_auth_host=172.18.168.5

#cd $WORKSPACE/savanna
mysql -usavanna-citest -psavanna-citest -Bse "DROP DATABASE IF EXISTS savanna"
mysql -usavanna-citest -psavanna-citest -Bse "create database savanna"

echo -e "[DEFAULT]
os_admin_username=dep-user
os_admin_tenant_name=dep
os_auth_host=$os_auth_host
os_auth_port=5000
os_admin_password=$os_admin_password
use_neutron=True
[keystone_authtoken]
auth_uri=http://$os_auth_host:5000/v2.0/
identity_uri=http://$os_auth_host:35357/
admin_user=dep-user
admin_password=swordfish
admin_tenant_name=dep
[database]
connection=mysql://savanna-citest:savanna-citest@localhost/savanna?charset=utf8" > etc/sahara/sahara.conf

rm -rf .tox

exist=`screen -ls | grep savanna-master`
if ! [ -z "$exist" ]
then
    screen -X -S savanna-master quit
fi
screen -dmS savanna-master
sleep 2
tox -evenv -- sahara-db-manage --config-file etc/sahara/sahara.conf upgrade head
screen -S savanna-master -p 0 -X stuff 'tox -evenv -- sahara-api --config-file etc/sahara/sahara.conf -d
'
