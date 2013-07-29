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
screen -dmS savanna-api /bin/bash -c "tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file log.txt | tee /tmp/tox-log.txt"


export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`
echo "OS_USERNAME = 'ci-user'  # username for nova
OS_PASSWORD = 'swordfish'  # password for nova
OS_TENANT_NAME = 'ci'
OS_AUTH_URL = 'http://172.18.168.5:35357/v2.0/'
SAVANNA_HOST = '$ADDR'
SAVANNA_PORT = '8386'
IMAGE_ID = 'b244500e-583a-434f-a40f-6ba87fd55e09'
FLAVOR_ID = '42'
NODE_USERNAME = 'ubuntu'
CLUSTER_NAME_CRUD = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER-crud'
CLUSTER_NAME_HADOOP = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER-hadoop'
CLUSTER_NAME_SWIFT = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER-swift'
CLUSTER_NAME_SCALING = 'ci-$BUILD_NUMBER-$GERRIT_PATCHSET_NUMBER-scaling'
TIMEOUT = 15
HADOOP_VERSION = '1.1.2'
HADOOP_DIRECTORY = '/usr/share/hadoop'
HADOOP_LOG_DIRECTORY = '/mnt/log/hadoop/hadoop/userlogs'
SSH_KEY = 'public-jenkins'
PLUGIN_NAME = 'vanilla'
PATH_TO_SSH = '/home/ubuntu/.ssh/id_rsa'
NAMENODE_CONFIG = {'Name Node Heap Size': 1234}
JOBTRACKER_CONFIG = {'Job Tracker Heap Size': 1345}
DATANODE_CONFIG = {'Data Node Heap Size': 1456}
TASKTRACKER_CONFIG = {'Task Tracker Heap Size': 1567}
GENERAL_CONFIG = {'Enable Swift': True}
CLUSTER_HDFS_CONFIG = {'dfs.replication': 2}
CLUSTER_MAPREDUCE_CONFIG = {'mapred.map.tasks.speculative.execution': False,
                            'mapred.child.java.opts': '-Xmx100m'}
JT_PORT = 50030
NN_PORT = 50070
TT_PORT = 50060
DN_PORT = 50075
ENABLE_SWIFT_TEST = True
" >> $WORKSPACE/savanna/tests/integration/configs/config.py
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
