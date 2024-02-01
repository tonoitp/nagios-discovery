#!/bin/bash
#

source nagios_discover-config.sh

function discover() {
#####
# UDP not yet functional
# open/closed required but currently all tested for open regardless
    portcheck "open"     20 "tcp" "FTP data"
    portcheck "open"     21 "tcp" "FTP control"
    portcheck "open"     22 "tcp" "ssh"
    portcheck "open"     23 "tcp" "telnet"
    portcheck "open"     25 "tcp" "smtp"
    portcheck "open"     80 "tcp" "http"
    portcheck "open"    443 "tcp" "https"
}

function Generic_Ping() {
    if [ ! -f "$Discover_DirServices/ping.cfg" ] ; then
        echo "define service {"                                            > "$Discover_DirServices/ping.cfg"
        echo "    use                     generic-service"                >> "$Discover_DirServices/ping.cfg"
        echo "    host_name               .*"                             >> "$Discover_DirServices/ping.cfg"
        echo "    service_description     Ping"                           >> "$Discover_DirServices/ping.cfg"
        echo "    check_command           check_ping!200.0,20%!600.0,60%" >> "$Discover_DirServices/ping.cfg"
        echo "    check_interval          5"                              >> "$Discover_DirServices/ping.cfg"
        echo "    retry_interval          1"                              >> "$Discover_DirServices/ping.cfg"
        echo "}"                                                          >> "$Discover_DirServices/ping.cfg"
    fi
}

function tcp_open(){
    if $PluginDir/check_tcp -H $1 -p $2 >> /dev/null ; then
        return 0
    fi
    return 1
}

function udp_open(){
    if $PluginDir/check_udp -H $1 -p $2 >> /dev/null ; then
        return 0
    fi
    return 1
}

function tcpudpcheck() {
    if [ "$3" == "udp" ] ; then
	    return $(udp_open $1 $2)
    else
	    return $(tcp_open $1 $2)
    fi
}

function AddService() {
    SvcGrp=` echo "group_$5" | sed 's/ /_/g' `
    echo "define service {"                  >  "$Discover_DirServices/$HostName.$3.cfg"
    echo "    use local-service"            >>  "$Discover_DirServices/$HostName.$3.cfg"
    echo "    host_name $HostName"          >>  "$Discover_DirServices/$HostName.$3.cfg"
    echo "    service_description $5"       >>  "$Discover_DirServices/$HostName.$3.cfg"
    echo "    servicegroups $SvcGrp"        >>  "$Discover_DirServices/$HostName.$3.cfg"
    echo "    check_command check_tcp!$3"   >>  "$Discover_DirServices/$HostName.$3.cfg"
    echo "    notifications_enabled 0"      >>  "$Discover_DirServices/$HostName.$3.cfg"
    echo "}"                                >>  "$Discover_DirServices/$HostName.$3.cfg"
}

function portcheck (){
    for file in $Discover_DirHosts/*.cfg ; do
        HostIp=`grep addr $file | sed 's/[ ][ ]*/ /g' | cut -f 3 -d ' ' `
        HostName=`grep host_name $file | sed 's/[ ][ ]*/ /g' | cut -f 3 -d ' ' `

        if tcpudpcheck $HostIp $2 $3 ; then
            AddService $HostIp $HostName $2 $3 "$4"
	fi
    done

    # Add servicegroup for port
    SvcName=` echo "group_$4" | sed 's/ /_/g' `
    echo "define servicegroup { "                  > "$Discover_DirServices/$SvcName.cfg"
    echo "    servicegroup_name       $SvcName"   >> "$Discover_DirServices/$SvcName.cfg"
    echo "    alias                   $SvcName"   >> "$Discover_DirServices/$SvcName.cfg"
    echo "}"                                      >> "$Discover_DirServices/$SvcName.cfg"

}

function Init() {
    mkdir -p $Discover_DirServices
    if [ $(grep -ic "$Discover_DirServices" "$nagios_cfg") -ne 1 ]
    then
        echo "cfg_dir=$Discover_DirServices" >> "$nagios_cfg"
    fi
}


Init
Generic_Ping
discover
NagiosRestart

