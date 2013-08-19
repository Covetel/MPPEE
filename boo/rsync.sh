#!/bin/bash

rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzr -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@boo.mppee.gob.ve:/var/log var/log
ssh root@boo.mppee.gob.ve dpkg -l > packages.txt
ssh root@boo.mppee.gob.ve uname -a  > kernel.txt
