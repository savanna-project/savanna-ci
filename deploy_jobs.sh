#!/bin/bash
find $1 -type f | while read FILENAME; do
     jenkins-jobs --ignore-cache --conf /etc/jenkins_jobs/jenkins_jobs.ini update "$FILENAME"
done
