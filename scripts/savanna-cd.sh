#!/bin/bash

# Next instcruction includes file "params", which contains values for savanna_cd.conf. For example:
# #!/bin/bash
# os_auth_host=127.0.0.1
# os_auth_port=35357
# os_admin_password=swordfish
db_name=savanna-server.db

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

lab=$(pwd | grep cz)
if [ -z $lab ]; then
    os_auth_host=172.18.79.139
else
    os_auth_host=172.18.168.2
fi

cd $WORKSPACE/savanna


echo -e "[DEFAULT]
os_admin_username=ci-user
os_admin_tenant_name=ci
os_auth_host=$os_auth_host
os_auth_port=5000
os_admin_password=$os_admin_password
plugins=vanilla,hdp,idh
use_neutron=True
[database]
connection=sqlite:////$WORKSPACE/$db_name
[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider
[plugin:hdp]
plugin_class=savanna.plugins.hdp.ambariplugin:AmbariPlugin" > etc/sahara/sahara.conf

rm -rf .tox

exist=`screen -ls | grep savanna-master`
if ! [ -z "$exist" ]
then
    screen -X -S savanna-master quit
    rm $WORKSPACE/$db_name
fi
screen -dmS savanna-master
sleep 2
tox -evenv -- sahara-db-manage --config-file etc/sahara/sahara.conf upgrade head
screen -S savanna-master -p 0 -X stuff 'tox -evenv -- sahara-api --config-file etc/sahara/sahara.conf -d
'
