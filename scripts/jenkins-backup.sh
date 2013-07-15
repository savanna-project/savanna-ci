#!/bin/bash

cd $WORKSPACE

date=`date '+%Y_%m_%d_%H_%M'`
name=backup_jenkins_$date
cd /tmp
if [ -d jenkins-backup/ ]
then
    rm -rf jenkins-backup
fi
git clone ssh://elastic-hadoop-jenkins@gerrit.mirantis.com:29418/savanna/jenkins-backup.git
cd ~
tar -C /var/lib/jenkins -cf $name.tar.gz `find . -name "*.xml"`
tar -C /var/lib/jenkins -rf $name.tar.gz `find . -type l | grep last`
mkdir /var/lib/jenkins/$name
tar -C /var/lib/jenkins/$name -xf /var/lib/jenkins/$name.tar.gz
rm /var/lib/jenkins/$name.tar.gz
wget --directory-prefix=/var/lib/jenkins/$name http://localhost:8080/pluginManager/api/xml?depth=1
cat /var/lib/jenkins/$name/xml?depth=1 | sed 's/></>\n</g' > /var/lib/jenkins/$name/plugins_info
rm /var/lib/jenkins/$name/xml?depth=1
echo -e '#!/bin/bash
plugins=`grep -o "<shortName>.*</shortName>" ./plugins_info | sed "s/<\/.*>//g" | sed "s/<.*>//g"`
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
for plugin in $plugins
do
\tjava -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin $plugin
done' > /var/lib/jenkins/$name/plugins_install.sh
chmod 755 /var/lib/jenkins/$name/plugins_install.sh
mv /var/lib/jenkins/$name /tmp/jenkins-backup
cd /tmp/jenkins-backup
git config --global user.email "elastic-hadoop-jenkins@gerrit.mirantis.com"
git config --global user.name "elastic-hadoop-jenkins"
git add $name
git commit -m "New $name"
git push origin master
