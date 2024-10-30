#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

IDMVersion()
{
		instRPMVersion=`rpm -qa --queryformat '%{version}' novell-DXMLengnx`
        echo "$instRPMVersion"
        return
}

IDMRLVersion()
{
		instRPMVersion=`rpm -qa --queryformat '%{version}' novell-DXMLrdxmlx`
        echo "$instRPMVersion"
        return
}

IDMFOVersion()
{
        instRPMVersion=`rpm -qa --queryformat '%{version}' novell-DXMLfanoutagent`
		echo "$instRPMVersion"
        return
}

eDirVersion()
{
        instRPMVersion=`rpm -qa --queryformat '%{version}' novell-NDSserv`
		echo "$instRPMVersion"
        return
}

iManagerVersion()
{
        instRPMVersion=`rpm -qa --queryformat '%{version}' novell-imanager`
		echo "$instRPMVersion"
        return
}

UAAppVersion()
{
	rpm -qi netiq-userapp &> /dev/null
   if [ $? -eq 0 ]
   then
   	instVersion=`rpm -qa --queryformat '%{version}' netiq-userapp` && instVersion=`echo \""$instVersion\""`
   elif [ -f "/etc/init.d/idmapps_tomcat_init" ]
   then
     local OLD_INSTALL_BASE_PATH=`grep -r "TOMCAT_PARENT_DIR=" /etc/init.d/idmapps_tomcat_init | cut -d "=" -f2`
     OLD_IDM_TOMCAT_HOME=$OLD_INSTALL_BASE_PATH/tomcat
	 rm -f ${OLD_IDM_TOMCAT_HOME}/webapps/build-info.json
	 unzip ${OLD_IDM_TOMCAT_HOME}/webapps/idmdash.war build-info.json -d ${OLD_IDM_TOMCAT_HOME}/webapps/ &> /dev/null
	 file_to_check=${OLD_IDM_TOMCAT_HOME}/webapps/idmdash/build-info.json
	 if [ ! -f $file_to_check ]
	 then
		file_to_check=${OLD_IDM_TOMCAT_HOME}/webapps/build-info.json
		if [ ! -f $file_to_check ] && [ -f ${OLD_IDM_TOMCAT_HOME}/webapps/dash.war ]
		then
			# 45x
			rm -rf ${OLD_IDM_TOMCAT_HOME}/webapps/META-INF
			unzip ${OLD_IDM_TOMCAT_HOME}/webapps/dash.war META-INF/maven/com.netiq.uadash/uadash/pom.properties -d ${OLD_IDM_TOMCAT_HOME}/webapps/ &> /dev/null
			instVersion=`grep version ${OLD_IDM_TOMCAT_HOME}/webapps/META-INF/maven/com.netiq.uadash/uadash/pom.properties | cut -d"=" -f2`
			instVersion=`echo \""$instVersion\""`
			instVersion=$(echo $instVersion | tr -d '"')
			rm -rf ${OLD_IDM_TOMCAT_HOME}/webapps/META-INF
			echo "$instVersion"
			return
		fi
	 fi
     if [ -f ${file_to_check} ]
     then
        instVersion=`cat "${file_to_check}" | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^version/ {print $2}'`
	if [ ! -z "$instVersion" ]
	then
		if [ `echo $instVersion | grep -c "SNAPSHOT" ` -gt 0 ]
		then
			instVersion=`echo $instVersion | awk -F- '{ print $1}'`
			instVersion=`echo "$instVersion\""`
			instVersion=$(echo $instVersion | tr -d '"')
		fi
	fi
     else
        instVersion=
     fi
	 rm -f ${OLD_IDM_TOMCAT_HOME}/webapps/build-info.json
   elif [ -f /opt/netiq/idm/apps/tomcat/webapps/idmdash/build-info.json ]
   then
   	instVersion=`cat "/opt/netiq/idm/apps/tomcat/webapps/idmdash/build-info.json" | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^version/ {print $2}'`
	if [ ! -z "$instVersion" ]
	then
		if [ `echo $instVersion | grep -c "SNAPSHOT" ` -gt 0 ]
		then
			instVersion=`echo $instVersion | awk -F- '{ print $1}'`
			instVersion=`echo "$instVersion\""`
			instVersion=$(echo $instVersion | tr -d '"')
		fi
	fi
   else
      instVersion=
   fi

   instVersion=$(echo $instVersion | tr -d '"')
   echo "$instVersion"
   return
}

ReportingAppVersion()
{
	rpm -qi netiq-IDMRPT &> /dev/null
   if [ $? -eq 0 ]
   then
   	instVersion=`rpm -qa --queryformat '%{version}' netiq-IDMRPT` && instVersion=`echo "$instVersion"`
   elif [ -f "/etc/init.d/idmapps_tomcat_init" ] 
   then
     local OLD_INSTALL_BASE_PATH=`grep -r "TOMCAT_PARENT_DIR=" /etc/init.d/idmapps_tomcat_init | cut -d "=" -f2`
     OLD_IDM_TOMCAT_HOME=$OLD_INSTALL_BASE_PATH/tomcat
	 rm -f ${OLD_IDM_TOMCAT_HOME}/webapps/build-info.json
	 unzip ${OLD_IDM_TOMCAT_HOME}/webapps/IDMRPT-CORE.war build-info.json -d ${OLD_IDM_TOMCAT_HOME}/webapps/ &> /dev/null
	 file_to_check=${OLD_IDM_TOMCAT_HOME}/webapps/IDMRPT-CORE/build-info.json
	 if [ ! -f $file_to_check ]
	 then
		file_to_check=${OLD_IDM_TOMCAT_HOME}/webapps/build-info.json
	 fi
     if [ -f ${file_to_check} ]
     then
        instVersion=`cat "${file_to_check}" | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^version/ {print $2}'`
	if [ ! -z "$instVersion" ]
	then
		if [ `echo $instVersion | grep -c "SNAPSHOT" ` -gt 0 ]
		then
			instVersion=`echo $instVersion | awk -F- '{ print $1}'`
			instVersion=`echo "$instVersion\""`
			instVersion=$(echo $instVersion | tr -d '"')
		fi
	fi
     else
        instVersion=
     fi
	 rm -f ${OLD_IDM_TOMCAT_HOME}/webapps/build-info.json
   elif [ -f /opt/netiq/idm/apps/tomcat/webapps/IDMRPT-CORE/build-info.json ]
   then
   	instVersion=`cat "/opt/netiq/idm/apps/tomcat/webapps/IDMRPT-CORE/build-info.json" | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^version/ {print $2}'`
	if [ ! -z "$instVersion" ]
	then
		if [ `echo $instVersion | grep -c "SNAPSHOT" ` -gt 0 ]
		then
			instVersion=`echo $instVersion | awk -F- '{ print $1}'`
			instVersion=`echo "$instVersion\""`
			instVersion=$(echo $instVersion | tr -d '"')
		fi
	fi
   else
        instVersion=
   fi

   instVersion=$(echo $instVersion | tr -d '"')
   echo "$instVersion"
   return
}
