#!/bin/bash
find $1 -type f | while read FILENAME; do
     jenkins-jobs update "$FILENAME"
done
