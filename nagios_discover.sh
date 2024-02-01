#!/bin/bash

LockFile="/tmp/run.lock"

# Not much of a problem, but run only one at a time
if [ -f $LockFile ] ; then
    date >> run.log
    echo "Lockfile ($LockFile) found" >> run.log
    exit 1
fi
touch $LockFile

date > run.log
echo "Discover hosts" >> run.log
time ./nagios_discover_hosts.sh >> run.log

date >> run.log
echo "Discover services" >> run.log
time ./nagios_discover_services.sh >> run.log

date >> run.log
echo "Discover snmp" >> run.log
time ./nagios_discover_snmp.sh >> run.log

date >> run.log
echo "Discover DONE" >> run.log

chown -R nagios:nagios *
rm $LockFile
