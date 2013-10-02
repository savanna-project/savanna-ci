#!/bin/bash -e

sudo pip install $WORKSPACE

SAVANNA_LOG=/tmp/savanna.log 

SCR_CHECK=$(ps aux | grep screen)
if [ -n "$SCR_CHECK" ]; then
     screen -S savanna -X quit
     screen -S display -X quit
fi

rm -f /tmp/savanna-server.db
rm -rf /tmp/cache

BUILD_ID=dontKill

screen -dmS display sudo Xvfb -fp /usr/share/fonts/X11/misc/ :22 -screen 0 1024x768x16

export DISPLAY=:22

cd /home/ubuntu && screen -dmS savanna /bin/bash -c "savanna-venv/bin/python savanna-venv/bin/savanna-api --config-file savanna-venv/etc/savanna.conf -d --log-file /tmp/savanna.log"

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
await_element = 30
image_name_for_register = 'fedora-18-hadoop'
[vanilla]
skip_plugin_tests = False
[hdp]
skip_plugin_tests = True
" >> $WORKSPACE/savannadashboard/tests/configs/config.conf

cd $WORKSPACE && tox -e tests
