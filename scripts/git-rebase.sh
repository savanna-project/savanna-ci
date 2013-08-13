#!/bin/bash -e

cd $WORKSPACE
git fetch origin master

if [ $? != 0 ]
then
    echo "ERROR. git fetch failed"
    return 1
else
   git rebase master
   git clean -x -f -d
fi
