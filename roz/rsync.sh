#!/bin/bash

mkdir -p etc/
mkdir -p var/log
rsync -avzrP -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@roz.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzrP -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@roz.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzrP -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@roz.mppee.gob.ve:/var/log/ var/log/

ssh root@roz.mppee.gob.ve dpkg -l > packages.txt
ssh root@roz.mppee.gob.ve uname -a  > kernel.txt
