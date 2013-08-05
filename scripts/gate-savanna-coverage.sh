rm -rf .tox
tox -evenv – coverage report --omit="/openstack/common/",".tox/","savanna/tests/"
