#!/bin/bash

cd $WORKSPACE
cat > script.py << EOL
from launchpadlib.launchpad import Launchpad

lp = Launchpad.login_anonymously('savanna-bad-bps', 'production',
                                 '/tmp/savanna-bad-bps',
                                 version="devel", timeout=10)

function check_bps_approver(project_name):
    bps = lp.projects[project_name].all_specifications 

    print "Total BPs: %s" % len(bps)
    for bp in bps:
        approver = bp.approver
        if approver and approver.name == u'slukjanov':
            continue
        print "Bad BP: %s (%s)" % (bp.name, bp.web_link)
        
        
check_bps_approver("savanna")
check_bps_approver("python-savannaclient")
EOL
python script.py > report.txt
