#!/bin/bash
export ADDR=`ifconfig eth0| awk -F ' *|:' '/inet addr/{print $4}'`
echo "OS_USERNAME = 'ci-user'  # username for nova
OS_PASSWORD = 'swordfish'  # password for nova
OS_TENANT_NAME = 'ci'
OS_AUTH_URL = 'http://172.18.168.5:35357/v2.0/'
SAVANNA_HOST = '$ADDR'
SAVANNA_PORT = '8080'
IMAGE_ID = 'b244500e-583a-434f-a40f-6ba87fd55e09'
FLAVOR_ID = '42'
NODE_USERNAME = 'ubuntu'
CLUSTER_NAME_CRUD = 'ci-cluster-crud'
CLUSTER_NAME_HADOOP = 'ci-cluster-hadoop'
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
" >> /tmp/workspace/itests-configure-vm/savanna/tests/integration/configs/config.py
i=0
while true
do
        let "i=$i+1"
        if [ "$i" -gt "60" ]; then
                echo "project does not start" && exit 1
        fi
        if [ ! -f /tmp/workspace/itests-configure-vm/log.txt ]; then
                sleep 10
        else
                echo "project is started" && break
        fi
done
cd /tmp/workspace/itests-configure-vm && tox -e integration
