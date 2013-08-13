#!/bin/bash

mkdir -p etc/
mkdir -p var/log
rsync -avzrP -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@cosmo.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzrP -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@cosmo.mppee.gob.ve:/etc/bind/ etc/bind/
rsync -avzrP -e 'ssh  -i /home/elsanto/.ssh/covetel_rsa' root@cosmo.mppee.gob.ve:/var/log/ var/log/

ssh root@cosmo.mppee.gob.ve dpkg -l > packages.txt
ssh root@cosmo.mppee.gob.ve uname -a  > kernel.txt
