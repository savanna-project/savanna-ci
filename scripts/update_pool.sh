#!/bin/bash

source /opt/ci/nodepool/bin/activate

for i in $(nodepool list | grep ci-lab | awk -F '|' '{ print $2 }'); do nodepool delete $i; done
