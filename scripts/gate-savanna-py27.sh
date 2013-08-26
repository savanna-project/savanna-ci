rm -rf .tox
tox -e py27
STATUS=`echo $?`

echo "-----------Python env-----------"
.tox/py27/bin/pip freeze

if [[ "$STATUS" != 0 ]]
then 
    exit 1
fi
