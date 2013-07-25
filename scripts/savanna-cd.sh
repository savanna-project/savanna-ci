#!/bin/bash

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

cd $WORKSPACE/savanna_$GERRIT_CHANGE_NUMBER

echo -e "[DEFAULT]
#REST API config
#port=8080
#allow_cluster_ops=true
# Address and credentials that will be used to check auth tokens
os_auth_host=172.18.79.139
os_auth_port=35357
#os_admin_username=admin
os_admin_password=swordfish
#os_admin_tenant_name=admin
# (Optional) Name of log file to output to. If not set,
# logging will go to stdout. (string value)
#log_file=<None>
plugins=vanilla,hdp
[cluster_node]
# An existing user on Hadoop image (string value)
#username=root
# User's password (string value)
#password=swordfish
# When set to false, Savanna uses only internal IP of VMs.
# When set to true, Savanna expects OpenStack to auto-assign
# floating IPs to cluster nodes. Internal IPs will be used for
# inter-cluster communication, while floating ones will be
# used by Savanna to configure nodes. Also floating IPs will
# be exposed in service URLs (boolean value)
#use_floating_ips=true
[database]
# URL for sqlalchemy database (string value)
connection=sqlite:////tmp/savanna-server-$GERRIT_CHANGE_NUMBER.db
[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider
[plugin:hdp]
plugin_class=savanna.plugins.hdp.ambariplugin:AmbariPlugin" > etc/savanna/savanna.conf

exist=`screen -ls | grep Savanna-$GERRIT_CHANGE_NUMBER`
if ! [ -z "$exist" ]
then
    screen -X -S Savanna-$GERRIT_CHANGE_NUMBER quit
fi
if [ $GERRIT_EVENT_TYPE != "patchset-created" ]
then
    exist=`screen -ls | grep Savanna-8080`
    if ! [ -z "$exist" ]
    then
        old_master=`ps aux | grep -e "config-file etc/savanna/savanna.conf -d" | grep -o "savanna_[0-9]*" | awk -F "_" '{print $2}'`
        screen -X -S Savanna-8080 quit
        rm -rf $WORKSPACE/savanna_$old_master
    fi
    screen -dmS Savanna-8080
    sleep 2
    screen -S Savanna-8080 -p 0 -X stuff 'tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d
'
else
    screen -dmS Savanna-$GERRIT_CHANGE_NUMBER
    sleep 2
    screen -S Savanna-$GERRIT_CHANGE_NUMBER -p 0 -X stuff "tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf --port $GERRIT_CHANGE_NUMBER -d
"
fi
