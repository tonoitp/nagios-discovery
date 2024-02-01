#!/bin/bash

PluginDir="/usr/local/nagios/libexec"
Discover_DirHosts="/usr/local/nagios/etc/discovered_hosts"
Discover_DirServices="/usr/local/nagios/etc/discovered_services"
Discover_DirSnmp="/usr/local/nagios/etc/discovered_snmp"
nagios_cfg="/usr/local/nagios/etc/nagios.cfg"

DefaultCommunity="public"

if ! [[ -v PreSum ]] ; then
  PreSum=`find . -type f -iname "*" -exec cat {} \; | sha256sum`
fi

function NagiosRestart() {
    PostSum=`find . -type f -iname "*" -exec cat {} \; | sha256sum`
    if [ "$1" != "$PostSum" ] ; then
        systemctl restart nagios
    fi
}
