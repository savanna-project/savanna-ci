#!/bin/bash
cd /opt/ci/jenkins-jobs
rm -rf sahara-ci-config
git clone https://github.com/stackforge/sahara-ci-config
cd sahara-ci-config
sudo jenkins-jobs update jenkins_job_builder
