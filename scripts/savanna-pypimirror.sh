cd $WORKSPACE

cat <<EOF > mirror.yaml
cache-root: /var/pypimirror/cache

mirrors:
   - name: savanna
     projects:
       - https://github.com/stackforge/savanna
     output: /var/pypimirror/savanna
EOF

echo "==== CHECK mirror.yaml ===="
cat mirror.yaml
echo "==== UPDATING MIRROR ===="

tox -e venv -- run-mirror -c mirror.yaml
