#!/bin/bash -e

git fetch origin master
git rebase master
git clean -x -f -d
