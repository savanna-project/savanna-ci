#!/bin/bash

sleep 30
python /var/lib/jenkins/ci-python-scripts/prepare_vm.py cleanup -$PREV_BUILD-
