#!/bin/bash

cd $WORKSPACE

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
download-cache = ~/.pip/cache
[install]
use-mirrors = true
find-links = http://savanna-ci.vm.mirantis.net:8181/simple/
" > ~/.pip/pip.conf
screen -dmS savanna-api /bin/bash -c "tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file log.txt | tee /tmp/tox-log.txt"


export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "OS_USERNAME = 'ci-user'
OS_PASSWORD = 'swordfish'
OS_TENANT_ID = 'cc39ab50891f4eb0aec22e8d9ed553cd'
OS_TENANT_NAME = 'ci'
OS_AUTH_URL = 'http://172.18.168.5:35357/v2.0/'
SAVANNA_HOST = '$ADDR'
SAVANNA_PORT = '8386'
FLAVOR_ID = '42'
CLUSTER_CREATION_TIMEOUT = 15
TELNET_TIMEOUT = 5
ACTIVE_WORKER_TIMEOUT_FOR_NAMENODE = 5
CLUSTER_NAME = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER'
USER_KEYPAIR_ID = 'public-jenkins'
PATH_TO_SSH_KEY = '/home/ubuntu/.ssh/id_rsa'
JT_PORT = 50030
NN_PORT = 50070
TT_PORT = 50060
DN_PORT = 50075
SEC_NN_PORT = 50090
" >> $WORKSPACE/savanna/tests/integration_new/configs/common_config.py

echo "PLUGIN_NAME = 'hdp'
IMAGE_ID = '5ea141c3-893e-4b5c-b138-910adc09b281'
NODE_USERNAME = 'cloud-user'
HADOOP_VERSION = '1.3.0'
HADOOP_USER = 'hdfs'
HADOOP_DIRECTORY = '/usr/lib/hadoop'
HADOOP_LOG_DIRECTORY = '/hadoop/mapred/userlogs'
" >> $WORKSPACE/savanna/tests/integration_new/configs/hdp_config.py

echo "PLUGIN_NAME = 'vanilla'
IMAGE_ID = '75615550-013c-426f-a6e5-dd3318950c20'
NODE_USERNAME = 'ubuntu'
HADOOP_VERSION = '1.1.2'
HADOOP_USER = 'hadoop'
HADOOP_DIRECTORY = '/usr/share/hadoop'
HADOOP_LOG_DIRECTORY = '/mnt/log/hadoop/hadoop/userlogs'
SKIP_CLUSTER_CONFIG_TEST = False
SKIP_MAP_REDUCE_TEST = False
SKIP_SWIFT_TEST = False
" >> $WORKSPACE/savanna/tests/integration_new/configs/vanilla_config.py

touch $TMP_LOG
i=0

while true
do
        let "i=$i+1"
        diff $TOX_LOG $TMP_LOG
        cp -f $TOX_LOG $TMP_LOG
        if [ "$i" -gt "480" ]; then
                echo "project does not start" && FAILURE=1 && break
        fi
        if [ ! -f $WORKSPACE/log.txt ]; then
                sleep 10
        else
                echo "project is started" && FAILURE=0 && break
        fi
done

if [ "$FAILURE" = 0 ]; then
   
    cd $WORKSPACE && tox -e integration -- -a tags=vanilla
fi

echo "-----------Python env-----------"
cd $WORKSPACE && .tox/integration/bin/pip freeze

screen -S savanna-api -X quit

echo "-----------Savanna Log------------"
cat $WORKSPACE/log.txt
rm -rf /tmp/workspace/
rm -rf /tmp/cache/

echo "-----------Tox log-----------"
cat /tmp/tox-log.txt
rm -f /tmp/tox-log.txt

rm -f /tmp/savanna-server.db
rm $TMP_LOG

if [ "$FAILURE" != 0 ]; then
    exit 1
fi
