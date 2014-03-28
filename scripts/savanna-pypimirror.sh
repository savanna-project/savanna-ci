cd $WORKSPACE

cat <<EOF > mirror.yaml
cache-root: /var/pypimirror/cache

mirrors:
   - name: savanna
     projects:
       - https://git.openstack.org/openstack/sahara
       - https://git.openstack.org/openstack/sahara-dashboard
       - https://git.openstack.org/openstack/sahara-image-elements
       - https://git.openstack.org/openstack/sahara-extra
       - https://git.openstack.org/openstack/python-saharaclient
     output: /var/pypimirror/savanna
EOF

echo "==== CHECK mirror.yaml ===="
cat mirror.yaml
echo "==== UPDATING MIRROR ===="

tox -e venv -- run-mirror -c mirror.yaml
