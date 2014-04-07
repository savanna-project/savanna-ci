#!/bin/bash
cd /opt/ci/jenkins-jobs
#java -jar jenkins-cli.jar -s http://localhost:8080 -i ~/.ssh/jenkins quiet-down
#sleep 5
rm -rf savanna-ci
git clone https://github.com/savanna-project/savanna-ci.git
#bash savanna-ci/deploy_jobs.sh savanna-ci/jobs/
#java -jar jenkins-cli.jar -s http://localhost:8080 -i ~/.ssh/jenkins cancel-quiet-down
cd savanna-ci
jenkins-jobs update new-jobs
