#!/bin/bash

cd $WORKSPACE

screen -S savanna-api -X quit
rm -f /tmp/savanna-server.db
rm -rf /tmp/cache                                                               

BUILD_ID=dontKill

sudo pip install tox
mkdir /tmp/cache

export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "[DEFAULT]
os_auth_host=172.18.168.5
os_admin_username=admin
os_admin_password=swordfish
os_admin_tenant_name=admin
plugins=vanilla,hdp
[cluster_node]
[sqlalchemy]
[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider
[plugin:hdp]
plugin_class=savanna.plugins.hdp.ambariplugin:AmbariPlugin" >> etc/savanna/savanna.conf

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
screen -dmS savanna-api /bin/bash -c "tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file log.txt | tee /tmp/tox-log.txt"


export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "OS_USERNAME = 'ci-user'
OS_PASSWORD = 'swordfish'
OS_TENANT_NAME = 'ci'
OS_AUTH_URL = 'http://172.18.168.5:35357/v3/'
SAVANNA_HOST = '$ADDR'
TIMEOUT = 240
CLUSTER_NAME = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER'
USER_KEYPAIR_ID = 'public-jenkins'
PATH_TO_SSH = '/home/ubuntu/.ssh/id_rsa'
$Common_parameters
" >> $WORKSPACE/savanna/tests/integration/configs/common_config.py

echo "PLUGIN_NAME = 'hdp'
IMAGE_ID = 'cd63f719-006e-4541-a523-1fed7b91fa8c'
NODE_USERNAME = 'root'
$HDP_parameters
" >> $WORKSPACE/savanna/tests/integration/configs/hdp_config.py

echo "PLUGIN_NAME = 'vanilla'
$Vanilla_parameters
" >> $WORKSPACE/savanna/tests/integration/configs/vanilla_config.py

i=0

while true
do
        let "i=$i+1"
        if [ "$i" -gt "120" ]; then
                echo "project does not start" && FAILURE=1 && break
        fi
        if [ ! -f $WORKSPACE/log.txt ]; then
                sleep 10
        else
                echo "project is started" && FAILURE=0 && break
        fi
done

if [ "$FAILURE" = 0 ]; then
   
    cd $WORKSPACE && tox -e integration
fi

screen -S savanna-api -X quit

echo "-----------Savanna Log------------"
cat $WORKSPACE/log.txt
rm -rf /tmp/workspace/
rm -rf /tmp/cache/

echo "-----------Tox log-----------"
cat /tmp/tox-log.txt
rm -f /tmp/tox-log.txt

rm -f /tmp/savanna-server.db


if [ "$FAILURE" != 0 ]; then
    exit 1
fi
