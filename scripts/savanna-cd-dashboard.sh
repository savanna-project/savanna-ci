#!/bin/bash

# Next instcruction includes file "params", which contains values for savanna_dashboard_cd.conf. For example:
# #!/bin/bash
# OPENSTACK_HOST=127.0.0.1
# SAVANNA_URL=http://127.0.0.1:8386/v1.0
# BRACNH=stable/folsom    (or stable/grizzly)

. $WORKSPACE/params

cd $WORKSPACE


BUILD_ID=dontKill
#echo -e "[global] 
#timeout = 60
#index-url = http://savanna-ci.vm.mirantis.net/pypi/savanna/
#extra-index-url = https://pypi.python.org/simple/
#download-cache = /home/ubuntu/.pip/cache/
#[install]
#use-mirrors = true
#find-links = http://savanna-ci.vm.mirantis.net:8181/simple/" > ~/.pip/pip.conf

cd $WORKSPACE/savanna-dashboard
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

exist=`screen -ls | grep savanna-dashboard-master`
if ! [ -z "$exist" ]
then
    screen -X -S savanna-dashboard-master quit
fi
screen -dmS savanna-dashboard-master
sleep 2
screen -S savanna-dashboard-master -p 0 -X stuff  ".venv/bin/python ./manage.py runserver 0.0.0.0:8080
"
