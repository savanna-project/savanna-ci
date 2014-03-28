cd $WORKSPACE

cat <<EOF > mirror.yaml
cache-root: /var/pypimirror/cache

mirrors:
   - name: savanna
     projects:
       - https://git.openstack.org/openstack/savanna
       - https://git.openstack.org/openstack/savanna-dashboard
       - https://git.openstack.org/openstack/savanna-image-elements
       - https://git.openstack.org/openstack/savanna-extra
       - https://git.openstack.org/openstack/python-savannaclient
     output: /var/pypimirror/savanna
EOF

echo "==== CHECK mirror.yaml ===="
cat mirror.yaml
echo "==== UPDATING MIRROR ===="

tox -e venv -- run-mirror -c mirror.yaml
