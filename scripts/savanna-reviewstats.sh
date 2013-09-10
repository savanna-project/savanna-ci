#!/bin/bash

user=savanna-ci
project=projects/savanna.json

cat > ${project} <<EOF
{ 
    "name": "savanna", 
    "subprojects": [
        "stackforge/savanna",  
        "stackforge/savanna-pythonclient", 
        "stackforge/savanna-dashboard",
        "stackforge/savanna-extra",
        "stackforge/savanna-image-elements",
        "stackforge/puppet-savanna"
    ], 
    "core-team": [
        "slukjanov",
        "aignatov",
        "farrellee",
        "jspeidel"
    ]
}
EOF

mkdir -p results

rm -f results/*-openreviews*
rm -f results/*-openapproved*
rm -f results/*-reviewers-*

project_base=$(basename $(echo ${project} | cut -f1 -d'.'))
(date -u && echo && ./openreviews.py -p ${project} -u ${user}) > results/${project_base}-openreviews.txt
./openreviews.py -p ${project} -u ${user} --html > results/${project_base}-openreviews.html
(date -u && echo && ./openapproved.py -p ${project} -u ${user}) > results/${project_base}-openapproved.txt

for time in 7 14 30 90 180 365 3650; do
    (date -u && echo && ./reviewers.py -p ${project} -d ${time} -u ${user}) > results/${project_base}-reviewers-${time}.txt
done

cat > results/index.html <<EOF
<html>
<head><title>Review Stats for ${project_base}</title></head>
<body>
<h3>Review Stats for ${project_base}</h3>
<ul>
  <li>Reviews Stats:</li>
    <ul>
      <li><a href="savanna-openreviews.html">General Reviews Stats</a></li>
      <li><a href="savanna-openapproved.txt">Open Approved Reviews</a></li>
    </ul>
  <li>Reviewers Stats:</li>
    <ul>
      <li><a href="savanna-reviewers-7.txt">Reviews for the last 7 days</a></li>
      <li><a href="savanna-reviewers-14.txt">Reviews for the last 14 days</a></li>
      <li><a href="savanna-reviewers-30.txt">Reviews for the last 30 days</a></li>
      <li><a href="savanna-reviewers-90.txt">Reviews for the last 90 days</a></li>
      <li><a href="savanna-reviewers-180.txt">Reviews for the last 180 days</a></li>
      <li><a href="savanna-reviewers-365.txt">Reviews for the last 365 days</a></li>
      <li><a href="savanna-reviewers-3650.txt">Reviews for the last 3650 days</a></li>
    </ul>
</ul>
</body>
</html>
EOF
