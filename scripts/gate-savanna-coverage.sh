rm -rf .tox
tox -e cover
STATUS=`echo $?`

if [[ "$STATUS" != 0 ]]
then
    exit 1
fi
