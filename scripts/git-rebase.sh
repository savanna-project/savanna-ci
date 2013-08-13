#!/bin/bash -e

cd $WORKSPACE
git fetch origin $1
git rebase origin/$1

if [ $? != 0 ]
then
    echo "ERROR. git rebase failed"
    return 1
else
   git clean -x -f -d
fi
