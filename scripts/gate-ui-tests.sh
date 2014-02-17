#!/bin/bash -e

sudo iptables -F

SAVANNA_LOG=/tmp/savanna.log 
SAVANNA_URL=http://127.0.0.1:8386/v1.1
OPENSTACK_HOST=172.18.168.42

SCR_CHECK=$(ps aux | grep screen | grep display)
if [ -n "$SCR_CHECK" ]; then
     screen -S display -X quit
fi

screen -S savanna -X quit

DETECT_XVFB=$(ps aux | grep Xvfb | grep -v grep)
if [ -n "$DETECT_XVFB" ]; then
     sudo killall Xvfb
fi

ps aux | grep Xvfb

#rm -f /tmp/savanna-server.db
rm -rf /tmp/cache

mysql -usavanna-citest -psavanna-citest -Bse "DROP DATABASE IF EXISTS savanna"
mysql -usavanna-citest -psavanna-citest -Bse "create database savanna"

BUILD_ID=dontKill

screen -dmS display sudo Xvfb -fp /usr/share/fonts/X11/misc/ :22 -screen 0 1024x768x16

export DISPLAY=:22

cd $HOME
rm -rf savanna

echo "
[DEFAULT]

os_auth_host=172.18.168.42
os_auth_port=5000
os_admin_username=ci-user
os_admin_password=nova
os_admin_tenant_name=ci
use_floating_ips=true
use_neutron=true

plugins=vanilla,hdp


[plugin:vanilla]
plugin_class=savanna.plugins.vanilla.plugin:VanillaProvider

[plugin:hdp]
plugin_class=savanna.plugins.hdp.ambariplugin:AmbariPlugin


[database]
connection=mysql://savanna-citest:savanna-citest@localhost/savanna?charset=utf8"  > savanna.conf

git clone https://github.com/openstack/savanna
cd savanna
tox -evenv -- savanna-db-manage --config-file $HOME/savanna.conf upgrade head
screen -dmS savanna /bin/bash -c "PYTHONUNBUFFERED=1 tox -evenv -- savanna-api --config-file $HOME/savanna.conf -d --log-file /tmp/savanna.log"

while true
do
        if [ ! -f $SAVANNA_LOG ]; then
                sleep 10
        else
                echo "project is started" && FAILURE=0 && break
        fi
done

#sudo service apache2 restart
#sleep 20

echo "
[common]
base_url = 'http://127.0.0.1:8080'
user = 'ci-user'
password = 'nova'
tenant = 'ci'
flavor = 'm1.small'
neutron_management_network = 'private'
floationg_ip_pool = 'public'
keystone_url = 'http://172.18.168.42:5000/v2.0'
await_element = 120
image_name_for_register = 'ubuntu-12.04'
image_name_for_edit = "savanna-itests-ci-vanilla-image"
[vanilla]
skip_plugin_tests = False
skip_edp_test = False
base_image = "savanna-itests-ci-vanilla-image"
[hdp]
skip_plugin_tests = False
hadoop_version = '1.3.2'
" >> $WORKSPACE/savannadashboard/tests/configs/config.conf

cd $WORKSPACE
if [ -d horizon/ ]
then
    rm -rf horizon
fi
git clone https://git.openstack.org/openstack/horizon
cd horizon
cp openstack_dashboard/local/local_settings.py.example openstack_dashboard/local/local_settings.py


sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"$OPENSTACK_HOST\"/g" openstack_dashboard/local/local_settings.py
sed -i "s/#from horizon.utils import secret_key/from horizon.utils import secret_key/g" openstack_dashboard/local/local_settings.py
sed -i "s/#SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))/SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))/g" openstack_dashboard/local/local_settings.py
echo -e "SAVANNA_USE_NEUTRON = True" >> openstack_dashboard/local/local_settings.py
echo -e "AUTO_ASSIGNMENT_ENABLED = False" >> openstack_dashboard/local/local_settings.py
echo -e "SAVANNA_URL = \"$SAVANNA_URL\"" >> openstack_dashboard/local/local_settings.py

sed -i "s/'openstack_dashboard'/'savannadashboard',\n    'openstack_dashboard'/g" openstack_dashboard/settings.py
echo "HORIZON_CONFIG['dashboards'] += ('savanna',)" >> openstack_dashboard/settings.py

python tools/install_venv.py
.venv/bin/pip install ../
ln -s $WORKSPACE/savanna-dashboard/savannadashboard .venv/lib/python2.7/site-packages/savannadashboard

exist=`screen -ls | grep savanna-dashboard-master`
if ! [ -z "$exist" ]
then
    screen -X -S savanna-dashboard-master quit
fi
screen -dmS savanna-dashboard-master
sleep 2
screen -S savanna-dashboard-master -p 0 -X stuff  ".venv/bin/python ./manage.py runserver 0.0.0.0:8080
"

cd $WORKSPACE && tox -e uitests
