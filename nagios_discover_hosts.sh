#!/bin/bash

source nagios_discover-config.sh

function discover(){
    scan_subnet "192.168.0.0/24"
    scan_subnet "10.0.0.0/24"
    scan_name   "mydomain.eu"
}

function add_host(){
    if [ ! -f "$Discover_DirHosts/$1.cfg" ] ; then
        HostName=`snmpget -Oqv -v2c -c $DefaultCommunity $1 iso.3.6.1.2.1.1.5.0 | tr -d '"' `
	if [ "$HostName" == "" ] ; then
		HostName=$1
	fi
	HostName=`echo $HostName | sed 's/\./-/g' `
        echo "define host {"                            >>  "$Discover_DirHosts/$1.cfg"
        echo "    use                     linux-server" >>  "$Discover_DirHosts/$1.cfg"
        echo "    alias                   $HostName"    >>  "$Discover_DirHosts/$1.cfg"
	HostName="${HostName}_${1}"
	HostName=`echo $HostName | sed 's/\./-/g' `
        echo "    host_name               $HostName"    >>  "$Discover_DirHosts/$1.cfg"
        echo "    address                 $1"           >>  "$Discover_DirHosts/$1.cfg"
        echo "}"                                        >> "$Discover_DirHosts/$1.cfg"
    fi
}

function ping_test(){
    ping -c 2 -q $1 > /dev/null
    if [ $? -eq 0 ]; then
        add_host $1
	return 1
    fi
    return 0
}

function scan_subnet() {
    GrpLst=""
    AddrList=`prips $1  | sed -e '1d; $d'`
    while IFS= read -r line; do
        ping_test $line
        if [ $? -eq 1 ] ; then
	    GrpLst=$GrpLst".*"$line","
	fi
    done <<< "$AddrList"

    GrpLst=`echo $GrpLst | sed 's/\./-/g' `
    # Add hostgroup for subnet
    # 
    if [ "$GrpLst" != "" ] ; then
        GrpName=` echo "group_$1" | sed 's/\//_/g' `
        echo "define hostgroup { "                     > "$Discover_DirHosts/$GrpName.cfg"
        echo "    hostgroup_name          $GrpName"   >> "$Discover_DirHosts/$GrpName.cfg"
        echo "    alias                   $GrpName"   >> "$Discover_DirHosts/$GrpName.cfg"
        echo "    members                 $GrpLst"    >> "$Discover_DirHosts/$GrpName.cfg"
        echo "}"                                      >> "$Discover_DirHosts/$GrpName.cfg"
    fi
}

function scan_name() {
    ping_test $1
}

function Init(){
    mkdir -p $Discover_DirHosts
    if [ $(grep -ic "$Discover_DirHosts" "$nagios_cfg") -ne 1 ]
    then
        echo "cfg_dir=$Discover_DirHosts" >> "$nagios_cfg"
    fi
}


Init
discover
NagiosRestart

