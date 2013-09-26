#!/bin/bash

# Next instcruction includes file "params", which contains values for savanna_cd.conf. For example:
# #!/bin/bash
# os_auth_host=127.0.0.1
# os_auth_port=35357
# os_admin_password=swordfish
# db_name=savanna-server.db

. $WORKSPACE/params

cd $WORKSPACE

BUILD_ID=dontKill
echo -e "[global] 
timeout = 60
index-url = http://savanna-ci.vm.mirantis.net/pypi/savanna/
extra-index-url = https://pypi.python.org/simple/
download-cache = /home/ubuntu/.pip/cache/
[install]
use-mirrors = true
find-links = http://savanna-ci.vm.mirantis.net:8181/simple/" > ~/.pip/pip.conf

cd $WORKSPACE/savanna

lab=$(pwd | grep cz)
if [ -z $lab ]; then
    os_auth_host=172.18.79.139
else
    os_auth_host=172.18.168.5
fi

echo -e "[DEFAULT]
os_auth_host=$os_auth_host
os_auth_port=$os_auth_port
os_admin_password=$os_admin_password
plugins=vanilla,hdp
[database]
connection=sqlite:////$WORKSPACE/$db_name
[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider
[plugin:hdp]
plugin_class=savanna.plugins.hdp.ambariplugin:AmbariPlugin" > etc/savanna/savanna.conf

exist=`screen -ls | grep savanna-master`
if ! [ -z "$exist" ]
then
    screen -X -S savanna-master quit
    rm $WORKSPACE/$db_name
fi
screen -dmS savanna-master
sleep 2
screen -S savanna-master -p 0 -X stuff 'tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d
'
