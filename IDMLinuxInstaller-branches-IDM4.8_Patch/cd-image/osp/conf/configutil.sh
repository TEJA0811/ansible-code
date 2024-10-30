#! /bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

app_home="/opt/netiq/idm/apps/osp"
tomcat_home="/opt/netiq/idm/apps/tomcat"
java_home="/opt/netiq/common/jre"
_conf_opt=
_usage="Usage: configutil.sh [-console (invoke in console mode; default is gui)] [-script <script-file>]"

while [ $# -gt 0 ]
do
  case $1 in
    '-h')
      echo $_usage; exit
    ;;
    '-console')
      _conf_opt=
    ;;
    '-script')
      _conf_opt=-script
      if [ $2 ]
        then
          _conf_opt="$_conf_opt $2"
          shift
        else
		  disp_str=`gettext install "missing script file name"`
          echo "$disp_str"; exit
      fi
    ;;
    *)
	  disp_str=`gettext install "unrecognised arg %s"`
    disp_str=`printf "$disp_str" "$1"`
      echo "$disp_str"; exit
      ;;
  esac
  shift
done

"$java_home/bin/java" -Dlog4j.configuration=file:///$app_home/conf/log4j-config.xml -Dcom.netiq.ism.config="$tomcat_home/conf/ism-configuration.properties" -jar "$app_home/lib/netiq-configutil.jar" -internalProps "$app_home/conf/internal.properties" $_conf_opt
