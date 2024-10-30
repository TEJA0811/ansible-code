#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

restart_lcache()
{
    #PA_ID=`ps -eo pid,args | grep lcache | grep int | grep -v grep | cut -c1-6`
    PA_ID=`ps -aef | grep -i lcache | grep int | grep novlua | awk -F " " '{print $2}' | xargs`
    if [ ! -z "${PA_ID}" ]
    then
        kill -15 $PA_ID 2>&1 > /dev/null &
        sleep 2
        ps -p $PA_ID  2>&1 >/dev/null
    fi
    
    [ ! -d /var/opt/novell  ] && mkdir /var/opt/novell
    
    if [ ! -e /var/opt/novell/naudit  ]
    then
        mkdir /var/opt/novell/naudit
    fi

    if [ ! -e /var/opt/novell/naudit/jcache  ]
    then
        mkdir /var/opt/novell/naudit/jcache
    fi

    
    /usr/bin/chmod -R ug+rw /var/opt/novell/naudit
    /usr/bin/chown -R novlua:idvadmin /var/opt/novell/naudit
#    /opt/novell/naudit/lcache -dir:/var/opt/novell/naudit/cache -port:1288 -slsport:1289 -int:600 -c &
}

set_uid_permissions_to_lcache()
{
        file=/opt/novell/naudit/lcache
        if [ -e $file ]
        then
        chmod 4755 $file
        fi
}


add_conf_entry()
{
local key_name=$1
local key_value=$2
local log_conf_file="/etc/logevent.conf"
    sed -i "s/^LogHost=Not Configured$//g" $log_conf_file
	# sed -i "s/^${key_name}=/d" $log_conf_file
    grep "^${key_name}=" $log_conf_file > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "$key_name=$key_value" >> $log_conf_file 2>&1
    fi


}


configure_audit()
{

    local log_conf_file="/etc/logevent.conf"
    if [ -e $log_conf_file -a -f $log_conf_file ]
    then

        add_conf_entry "LogHost" "${SENTINEL_AUDIT_SERVER}"
        add_conf_entry "JLogCacheDir" "/var/opt/novell/idm/audit"
        add_conf_entry "JLogCachePort" "1287"
        add_conf_entry "LogCachePort" "1288"
        add_conf_entry "LogJavaClassPath" "/opt/netiq/idm/apps/tomcat/lib/nauditpa-2011.1r5.jar"
        add_conf_entry "LogMaxBigData" "8192"
        add_conf_entry "LogEnginePort" "1289"
        add_conf_entry "LogCacheUnload" "no"
        add_conf_entry "LogCacheSecure" "no"
        add_conf_entry "LogCacheLimitAction" "keep logging"
        add_conf_entry "LogCacheDir" "/var/opt/novell/idm/audit"

    fi
    mkdir -p /var/opt/novell/idm/audit  
    chmod -R ug+rw /var/opt/novell/idm/audit

	if ! grep -q "^idvadmin:*" /etc/group
	then
		groupadd -r idvadmin
	fi

    chown -R novlua:idvadmin /var/opt/novell/idm/audit
    set_uid_permissions_to_lcache
    restart_lcache

}

