#!/bin/bash

cd $WORKSPACE
cat > script.py << EOL
from launchpadlib.launchpad import Launchpad

lp = Launchpad.login_anonymously('savanna-bad-bps', 'production',
                                 '/tmp/savanna-bad-bps',
                                 version="devel", timeout=10)

bps = (lp.projects['savanna'].all_specifications 
        + lp.projects['python-savannaclient'].all_specifications)

for bp in bps:
    approver = bp.approver
    if approver and approver.name == u'slukjanov':
        continue
    print "Bad BP: %s (%s)" % (bp.name, bp.web_link)
EOL
python script.py > report.txt
