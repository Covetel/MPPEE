#!/bin/bash

rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/var/log/syslog var/log/syslog
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/var/log/syslog.1.gz var/log/syslog.1.gz
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/var/log/syslog.2.gz var/log/syslog.2.gz
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/var/log/syslog.3.gz var/log/syslog.3.gz
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/var/log/syslog.4.gz var/log/syslog.4.gz
