#!/bin/bash
cd $WORKSPACE
if [ -z "`git config remote.mirantis-savanna.url`" ]; then
    echo "Remote 'mirantis-savanna': NO"
    git remote add mirantis-savanna git@github.com:Mirantis/savanna.git
    echo "Remote 'mirantis-savanna': ADDED"
else
    echo "Remote 'mirantis-savanna': YES"
fi
git fetch origin
git checkout master
git rebase origin/master
git push mirantis-savanna master:master
git push mirantis-savanna --tags
git checkout -b stable/0.1 origin/stable/0.1
git push mirantis-savanna stable/0.1:stable/0.1
git push mirantis-savanna --tags
