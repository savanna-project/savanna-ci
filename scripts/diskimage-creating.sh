#!/bin/bash

cd $WORKSPACE

ssh ubuntu@172.18.79.177 -i ~/.ssh/jenkins -o StrictHostKeyChecking=no "./DIB.sh -elements '$elements' -hadoop-version '$hadoop_version' -java-file '$java_file' -java-url '$java_url' -ubuntu-image-name '$ubuntu_image_name' -fedora-image-name '$fedora_image_name' -image-size '$image_size'"

scp -o StrictHostKeyChecking=no -i ~/.ssh/jenkins ubuntu@172.18.79.177:~/DIB_work/$ubuntu_image_name.qcow2 $WORKSPACE
scp -o StrictHostKeyChecking=no -i ~/.ssh/jenkins ubuntu@172.18.79.177:~/DIB_work/$fedora_image_name.qcow2 $WORKSPACE
ssh ubuntu@172.18.79.177 -i ~/.ssh/jenkins -o StrictHostKeyChecking=no "rm ~/DIB_work/$ubuntu_image_name.qcow2"
ssh ubuntu@172.18.79.177 -i ~/.ssh/jenkins -o StrictHostKeyChecking=no "rm ~/DIB_work/$fedora_image_name.qcow2"
