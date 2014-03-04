#!/bin/bash

#sudo sh -c 'grep -q controller /etc/hosts || echo 172.18.168.2 controller-13 >> /etc/hosts'
#sudo sh -c 'grep -q os4 /etc/hosts || echo 172.18.79.135 os4 >> /etc/hosts'
cd $WORKSPACE

OS_NAME=$3
OS_USERNAME=$2
VANILLA_IMAGE=$1
TOX_LOG=$WORKSPACE/.tox/venv/log/venv-1.log
TMP_LOG=/tmp/tox.log

screen -S savanna-api -X quit
rm -f /tmp/savanna-server.db
rm -rf /tmp/cache

BUILD_ID=dontKill

sudo pip install tox
mkdir /tmp/cache

export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "[DEFAULT]
os_auth_host=172.18.168.2
os_auth_port=5000
os_admin_username=ci-user
os_admin_password=swordfish
os_admin_tenant_name=ci
plugins=vanilla,hdp
use_neutron=true
[cluster_node]
[sqlalchemy]
[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider
[plugin:hdp]
plugin_class=savanna.plugins.hdp.ambariplugin:AmbariPlugin" >> etc/savanna/savanna.conf

screen -dmS savanna-api /bin/bash -c "PYTHONUNBUFFERED=1 tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file log.txt | tee /tmp/tox-log.txt"


export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "[COMMON]
OS_USERNAME = 'ci-user'
OS_PASSWORD = 'swordfish'
OS_TENANT_NAME = 'ci'
OS_TENANT_ID = 'fb35f224d9274d84866a77f887ea7b1c'
OS_AUTH_URL = 'http://172.18.168.2:5000/v2.0/'
SAVANNA_HOST = '$ADDR'
FLAVOR_ID = '22'
CLUSTER_CREATION_TIMEOUT = 60
CLUSTER_NAME = 'ci-$BUILD_NUMBER-diskimage'
FLOATING_IP_POOL = 'net04_ext'
NEUTRON_ENABLED = True
INTERNAL_NEUTRON_NETWORK = 'net04'
[VANILLA]
PLUGIN_NAME = 'vanilla'
IMAGE_NAME = '$VANILLA_IMAGE'
NODE_USERNAME = '$OS_USERNAME'
SKIP_ALL_TESTS_FOR_PLUGIN = False
SKIP_CLUSTER_CONFIG_TEST = True
SKIP_EDP_TEST = False
SKIP_MAP_REDUCE_TEST = False
SKIP_SWIFT_TEST = True
SKIP_SCALING_TEST = True
" >> $WORKSPACE/savanna/tests/integration/configs/itest.conf

touch $TMP_LOG
i=0

while true
do
        let "i=$i+1"
        diff $TOX_LOG $TMP_LOG
        cp -f $TOX_LOG $TMP_LOG
        if [ "$i" -gt "240" ]; then
                echo "project does not start" && FAILURE=1 && break
        fi
        if [ ! -f $WORKSPACE/log.txt ]; then
                sleep 10
        else
                echo "project is started" && FAILURE=0 && break
        fi
done

if [ "$FAILURE" = 0 ]; then 

    cd $WORKSPACE
    tox -e integration -- vanilla
    STATUS=`echo $?`               
fi

echo "-----------Python integration env-----------"
cd $WORKSPACE && .tox/integration/bin/pip freeze

screen -S savanna-api -X quit

echo "-----------Python savanna env-----------"
cd $WORKSPACE && .tox/venv/bin/pip freeze

echo "-----------Savanna Log------------"
cat $WORKSPACE/log.txt
rm -rf /tmp/workspace/
rm -rf /tmp/cache/

echo "-----------Tox log-----------"
cat /tmp/tox-log.txt
rm -f /tmp/tox-log.txt

rm -f /tmp/savanna-server.db
rm $TMP_LOG
rm -f $LOG_FILE

if [ "$FAILURE" != 0 ]; then
    exit 1
fi

if [[ "$STATUS" != 0 ]]
then
    exit 1
fi

mkdir -p $WORKSPACE

echo "id=\$(glance index | grep ${OS_NAME}_savanna_latest | cut -f 1 -d ' ')
glance image-delete \$id
id_new=\$(glance index | grep $VANILLA_IMAGE | cut -f 1 -d ' ')
glance image-update \$id_new --name ${OS_USERNAME}_savanna_latest
" >> $WORKSPACE/update-image.sh
