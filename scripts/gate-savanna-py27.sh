rm -rf .tox
tox -e py27

echo "-----------Python env-----------"
.tox/py27/bin/pip freeze
