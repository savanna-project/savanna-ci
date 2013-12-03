#!/bin/bash -e

#sudo pip install $WORKSPACE

SAVANNA_LOG=/tmp/savanna.log 

SCR_CHECK=$(ps aux | grep screen | grep display)
if [ -n "$SCR_CHECK" ]; then
     screen -S display -X quit
fi

SCR_CHECK=$(ps aux | grep screen | grep savanna)
if [ -n "$SCR_CHECK" ]; then
     screen -S savanna -X quit
fi

rm -f /tmp/savanna-server.db
rm -rf /tmp/cache

BUILD_ID=dontKill

screen -dmS display sudo Xvfb -fp /usr/share/fonts/X11/misc/ :22 -screen 0 1024x768x16

export DISPLAY=:22

cd /home/ubuntu/savanna && screen -dmS savanna /bin/bash -c "tox -evenv -- savanna-api --config-file etc/savanna/savanna.conf -d --log-file /tmp/savanna.log"

while true
do
        if [ ! -f $SAVANNA_LOG ]; then
                sleep 10
        else
                echo "project is started" && FAILURE=0 && break
        fi
done

echo "
[common]
base_url = 'http://127.0.0.1/horizon'
user = 'ci-user'
password = 'swordfish'
tenant = 'ci'
keystone_url = 'http://172.18.168.2:5000/v2.0'
await_element = 30
image_name_for_register = 'ci-workers'
[vanilla]
skip_plugin_tests = False
skip_edp_test = False
[hdp]
skip_plugin_tests = True
hadoop_version = '1.3.2'
" >> $WORKSPACE/savannadashboard/tests/configs/config.conf

cd $WORKSPACE
if [ -d horizon/ ]
then
    rm -rf horizon
fi
git clone https://git.openstack.org/openstack/horizon
cd horizon
git checkout $BRANCH
cp openstack_dashboard/local/local_settings.py.example openstack_dashboard/local/local_settings.py

lab=$(pwd | grep cz)
if [ -z $lab ]; then
    OPENSTACK_HOST=172.18.79.139
else
    OPENSTACK_HOST=172.18.168.2
fi

sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"$OPENSTACK_HOST\"/g" openstack_dashboard/local/local_settings.py
sed -i "s/#from horizon.utils import secret_key/from horizon.utils import secret_key/g" openstack_dashboard/local/local_settings.py
sed -i "s/#OPENSTACK_ENDPOINT_TYPE = \"publicURL\"/OPENSTACK_ENDPOINT_TYPE = \"publicURL\"/g" openstack_dashboard/local/local_settings.py
sed -i "s/#SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))/SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))/g" openstack_dashboard/local/local_settings.py
echo -e "SAVANNA_USE_NEUTRON = True" >> openstack_dashboard/local/local_settings.py
echo -e "AUTO_ASSIGNMENT_ENABLED = False" >> openstack_dashboard/local/local_settings.py
echo -e "SAVANNA_URL = \"$SAVANNA_URL\"" >> openstack_dashboard/local/local_settings.py

sed -i "s/'openstack_dashboard'/'savannadashboard',\n    'openstack_dashboard'/g" openstack_dashboard/settings.py
echo "HORIZON_CONFIG['dashboards'] += ('savanna',)" >> openstack_dashboard/settings.py

python tools/install_venv.py
.venv/bin/pip install ../
# Horizon doesn't start with Django==1.6 which is installed by default
.venv/bin/pip uninstall Django -y
.venv/bin/pip install Django==1.5
ln -s $WORKSPACE/savanna-dashboard/savannadashboard .venv/lib/python2.7/site-packages/savannadashboard

sudo service apache2 restart

cd $WORKSPACE && tox -e tests
STATUS=`echo $?`               
rm -r /tmp/savanna.db                              
if [[ "$STATUS" != 0 ]]        
then                               
    exit 1                    
fi 
