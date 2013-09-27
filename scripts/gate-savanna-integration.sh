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
download-cache = ~/.pip/cache
[install]
use-mirrors = true
find-links = http://savanna-ci.vm.mirantis.net:8181/simple/
" > ~/.pip/pip.conf
screen -dmS savanna-api /bin/bash -c "tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file log.txt | tee /tmp/tox-log.txt"


export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`

echo "[COMMON]
OS_USERNAME = 'ci-user'
OS_PASSWORD = 'swordfish'
OS_TENANT_NAME = 'ci'
OS_AUTH_URL = 'http://172.18.168.5:35357/v2.0/'
SAVANNA_HOST = '$ADDR'
SAVANNA_PORT = '8386'
SAVANNA_API_VERSION = 'v1.1'
FLAVOR_ID = '42'
CLUSTER_CREATION_TIMEOUT = 45
TELNET_TIMEOUT = 5
HDFS_INITIALIZATION_TIMEOUT = 5
CLUSTER_NAME = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER'
USER_KEYPAIR_ID = 'public-jenkins'
PATH_TO_SSH_KEY = '/home/ubuntu/.ssh/id_rsa'
[VANILLA]
PLUGIN_NAME = 'vanilla'
IMAGE_ID = 'e9691262-e286-46f7-aea5-9f40461b5eea'
NODE_USERNAME = 'ubuntu'
HADOOP_VERSION = '1.2.1'
HADOOP_USER = 'hadoop'
HADOOP_DIRECTORY = '/usr/share/hadoop'
HADOOP_LOG_DIRECTORY = '/mnt/log/hadoop/hadoop/userlogs'
HADOOP_PROCESSES_WITH_PORTS = jobtracker: 50030, namenode: 50070, tasktracker: 50060, datanode: 50075, secondarynamenode: 50090
PROCESS_NAMES = nn: namenode, tt: tasktracker, dn: datanode
SKIP_ALL_TESTS_FOR_PLUGIN = False
SKIP_CLUSTER_CONFIG_TEST = False
SKIP_MAP_REDUCE_TEST = False
SKIP_SWIFT_TEST = False
SKIP_SCALING_TEST = False
[HDP]
PLUGIN_NAME = 'hdp'
IMAGE_ID = 'cd63f719-006e-4541-a523-1fed7b91fa8c'
NODE_USERNAME = 'root'
HADOOP_VERSION = '1.3.0'
HADOOP_USER = 'hdfs'
HADOOP_DIRECTORY = '/usr/lib/hadoop'
HADOOP_LOG_DIRECTORY = '/hadoop/mapred/userlogs'
HADOOP_PROCESSES_WITH_PORTS = JOBTRACKER: 50030, NAMENODE: 50070, TASKTRACKER: 50060, DATANODE: 50075, SECONDARY_NAMENODE: 50090
PROCESS_NAMES = nn: NAMENODE, tt: TASKTRACKER, dn: DATANODE
SKIP_ALL_TESTS_FOR_PLUGIN = False
SKIP_MAP_REDUCE_TEST = False
SKIP_SCALING_TEST = False
" >> $WORKSPACE/savanna/tests/integration_new/configs/itest.conf

i=0

while true
do
        let "i=$i+1"
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
   
    cd $WORKSPACE && tox -e integration
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

if [ "$FAILURE" != 0 ]; then
    exit 1
fi
