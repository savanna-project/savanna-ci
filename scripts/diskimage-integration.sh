#!/bin/bash -e

sudo sh -c 'grep -q controller /etc/hosts || echo 172.18.168.5 controller-13 >> /etc/hosts'
sudo sh -c 'grep -q os4 /etc/hosts || echo 172.18.79.135 os4 >> /etc/hosts'
cd $WORKSPACE

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
OS_TENANT_NAME = 'ci'
OS_AUTH_URL = 'http://172.18.168.5:35357/v2.0/'
SAVANNA_HOST = '$ADDR'
SAVANNA_PORT = '8386'
FLAVOR_ID = '42'
TIMEOUT = 25
CLUSTER_NAME = 'ci-$BUILD_NUMBER-diskimage'
USER_KEYPAIR_ID = 'public-jenkins'
PATH_TO_SSH = '/home/ubuntu/.ssh/id_rsa'
JT_PORT = 50030
NN_PORT = 50070
TT_PORT = 50060
DN_PORT = 50075
SEC_NN_PORT = 50090
ENABLE_CLUSTER_CL_TEMPLATE_CRUD_TESTS = False
ENABLE_CLUSTER_NGT_NODE_PROCESS_CRUD_TESTS = False
ENABLE_CLUSTER_NGT_CRUD_TESTS = False
ENABLE_CLUSTER_NODE_PROCESS_CRUD_TESTS = False
ENABLE_CL_TEMPLATE_CRUD_TESTS = False
ENABLE_NGT_CRUD_TESTS = False
ENABLE_HADOOP_TESTS_FOR_VANILLA_PLUGIN = True
ENABLE_HADOOP_TESTS_FOR_HDP_PLUGIN = False
ENABLE_SWIFT_TESTS = False
ENABLE_SCALING_TESTS = False
ENABLE_CONFIG_TESTS = False
ENABLE_IR_TESTS = False
" >> $WORKSPACE/savanna/tests/integration/configs/common_config.py

echo "PLUGIN_NAME = 'hdp'
IMAGE_ID = '5ea141c3-893e-4b5c-b138-910adc09b281'
NODE_USERNAME = 'cloud-user'
HADOOP_VERSION = '1.3.0'
HADOOP_USER = 'hdfs'
HADOOP_DIRECTORY = '/usr/lib/hadoop'
HADOOP_LOG_DIRECTORY = '/hadoop/mapred/userlogs'
" >> $WORKSPACE/savanna/tests/integration/configs/hdp_config.py

echo "PLUGIN_NAME = 'vanilla'
IMAGE_ID = '$VANILLA_IMAGE'
NODE_USERNAME = '$OS_USERNAME'
HADOOP_VERSION = '1.1.2'
HADOOP_USER = 'hadoop'
HADOOP_DIRECTORY = '/usr/share/hadoop'
HADOOP_LOG_DIRECTORY = '/mnt/log/hadoop/hadoop/userlogs'
" >> $WORKSPACE/savanna/tests/integration/configs/vanilla_config.py

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
rm $TMP_LOG

if [ "$FAILURE" != 0 ]; then
    exit 1
fi
