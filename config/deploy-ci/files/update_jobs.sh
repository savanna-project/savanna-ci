#!/bin/bash
cd /opt/ci/jenkins-jobs
rm -rf savanna-ci
git clone https://github.com/savanna-project/savanna-ci.git
cd savanna-ci
sudo jenkins-jobs update new-jobs
