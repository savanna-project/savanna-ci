#!/bin/bash
cd $WORKSPACE
if [[ -z $JAVA_URL ]]
then
    ssh ubuntu@172.18.79.237 -i ~/.ssh/jenkins "~/buildImage.sh -java-file-name '$JAVA_FILENAME' -elements '$elements' -imageName '$imageName' -hadoop-version '$Hadoop_version'"
else
    ssh ubuntu@172.18.79.237 -i ~/.ssh/jenkins "~/buildImage.sh -java-url '$JAVA_URL' -elements '$elements' -imageName '$imageName' -hadoop-version '$Hadoop_version'"
fi
