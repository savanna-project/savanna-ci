#!/bin/bash -e

cd $WORKSPACE
git fetch origin $1
git rebase origin/$1

if [ $? != 0 ]
then
    git rebase --abort
    echo "ERROR. git rebase failed"
    exit 1
fi

#git clean -x -f -d

echo "================== REBASED =================="
echo "============== LATEST COMMITS ==============="
git log -10 --stat > latest_commits
cat latest_commits
echo "============================================="
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
