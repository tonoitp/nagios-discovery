#!/bin/bash
#

source nagios_discover-config.sh

function discover (){
    echo "to be done"
}

function Init() {
    mkdir -p $Discover_DirSnmp
    if [ $(grep -ic "$Discover_DirSnmp" "$nagios_cfg") -ne 1 ]
    then
        echo "cfg_dir=$Discover_DirSnmp" >> "$nagios_cfg"
    fi
}

Init
discover
NagiosRestart
