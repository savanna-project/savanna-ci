rm -rf .tox
tox -e pep8

echo "-----------Python env-----------"
.tox/pep8/bin/pip freeze
