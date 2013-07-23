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

cd $WORKSPACE
if [ -d horizon-$GERRIT_CHANGE_NUMBER/ ]
then
    rm -rf horizon-$GERRIT_CHANGE_NUMBER
fi
git clone https://github.com/openstack/horizon.git horizon-$GERRIT_CHANGE_NUMBER
cd horizon-$GERRIT_CHANGE_NUMBER
git checkout stable/folsom
cp openstack_dashboard/local/local_settings.py.example openstack_dashboard/local/local_settings.py

cat openstack_dashboard/local/local_settings.py | sed "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"172.18.79.139\"/g" | sed "s/#from horizon.utils import secret_key/from horizon.utils import secret_key/g" | sed "s/#SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))/SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))/g" > temp
cat temp > openstack_dashboard/local/local_settings.py
<<<<<<< HEAD
echo -e "SAVANNA_URL = \"http://172.18.79.253:8386/v1.0\"" >> openstack_dashboard/local/local_settings.py
=======
echo -e "SAVANNA_URL = \"http://172.18.79.253:8080/v1.0\"" >> openstack_dashboard/local/local_settings.py
>>>>>>> e8346d1563a9d65715d5e54efa64a017f2a9ff35

cat openstack_dashboard/settings.py | sed "s/('nova', 'syspanel', 'settings',)/('nova', 'syspanel', 'settings', 'savanna')/g" > temp
cat temp | sed "s/'openstack_dashboard'/'savannadashboard',\n    'openstack_dashboard'/g" > openstack_dashboard/settings.py
rm temp

python tools/install_venv.py
.venv/bin/python ../savanna-dashboard-$GERRIT_CHANGE_NUMBER/setup.py install
ln -s $WORKSPACE/savanna-dashboard-$GERRIT_CHANGE_NUMBER/savannadashboard .venv/lib/python2.7/site-packages/savannadashboard

exist=`screen -ls | grep savanna-dashboard-$GERRIT_CHANGE_NUMBER`
if ! [ -z "$exist" ]
then
    screen -X -S savanna-dashboard-$GERRIT_CHANGE_NUMBER quit
fi
if [ $GERRIT_EVENT_TYPE != "patchset-created" ]
then
    exist=`screen -ls | grep savanna-dashboard-8080`
    if ! [ -z "$exist" ]
    then
        old_master=`ps aux | grep /tmp/workspace/savanna-cd-dashboard/ | grep "0.0.0.0:8080" | grep -o "horizon-[0-9]*" | awk -F "-" '{print $2}'`
        screen -X -S savanna-dashboard-8080 quit
        rm -rf $WORKSPACE/horizon-$old_master $WORKSPACE/savanna-dashboard-$old_master
    fi
    screen -dmS savanna-dashboard-8080
    sleep 2
    screen -S savanna-dashboard-8080 -p 0 -X stuff  ".venv/bin/python ./manage.py runserver 0.0.0.0:8080
"
else
    screen -dmS savanna-dashboard-$GERRIT_CHANGE_NUMBER
    sleep 2
    screen -S savanna-dashboard-$GERRIT_CHANGE_NUMBER -p 0 -X stuff  ".venv/bin/python ./manage.py runserver 0.0.0.0:$GERRIT_CHANGE_NUMBER
"
fi
