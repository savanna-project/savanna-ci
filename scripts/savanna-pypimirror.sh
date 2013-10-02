cd $WORKSPACE

cat <<EOF > mirror.yaml
cache-root: /var/pypimirror/cache

mirrors:
   - name: savanna
     projects:
       - https://github.com/stackforge/savanna
       - https://github.com/stackforge/savanna-dashboard
       - https://github.com/stackforge/savanna-image-elements
       - https://github.com/stackforge/savanna-extra
       - https://github.com/stackforge/python-savannaclient
     output: /var/pypimirror/savanna
EOF

echo "==== CHECK mirror.yaml ===="
cat mirror.yaml
echo "==== UPDATING MIRROR ===="

tox -e venv -- run-mirror -c mirror.yaml
