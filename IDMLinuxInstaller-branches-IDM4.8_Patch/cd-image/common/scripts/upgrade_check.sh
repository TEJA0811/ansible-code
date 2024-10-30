#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

isIDMUpgRequired()
{
	# Usage
	# isIDMUpgRequired <non-root-DBPath> <returnAfterInstalledVersion>
	#
	# Usage 1
	# isIDMUpgRequired /root/eDirectory/opt/novell/eDirectory true
	#
	# Usage 2
	# isIDMUpgRequired /root/eDirectory/opt/novell/eDirectory
	#
	# Usage 3
	# isIDMUpgRequired
	#
	DBPATHasARG=""
	if [ "$1" != "" ]
	then
		DBPATHasARG="--dbpath=$1"
	fi
	 instRPMVersion=`rpm -qa $DBPATHasARG --queryformat '%{version}' novell-DXMLengnx`
	 if [ "$2" == "true" ]
	 then
	 	echo "$instRPMVersion"
		return
	 fi
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDM/packages/engine/novell-DXMLengnx*.rpm"`
	isUpgradeReq=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$SUPPORTED_IDM_VERSION'" }')

	if [ -z "$instRPMVersion" ]
	then
		echo "0"
		return
	fi

	if [ "$instRPMVersion" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed 
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isIDMRLUpgRequired()
{
	 instRPMVersion=`rpm -qa --queryformat '%{version}' novell-DXMLrdxmlx`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDM/packages/rl/x86_64/novell-DXMLrdxmlx*.rpm"`
	isUpgradeReq=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$SUPPORTED_IDM_RL_VERSION'" }')

	if [ -z "$instRPMVersion" ]
	then
		echo "0"
		return
	fi

	if [ "$instRPMVersion" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed 
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isIDVaultUpgRequired()
{
    if [ -z "$1" ]
	then
	    instRPMVersion=`rpm -qa --queryformat '%{version}' novell-NDSserv`
	else
		deduced_nonroot_path
	    cd "${NONROOT_IDVAULT_LOCATION}/bin"
	    . ndspath &> /dev/null
	    instRPMVersion=`./ndsstat | grep "Product Version" | awk '{ print $7 }' | tr -d v`
	    cd - &> /dev/null
	    fi

	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDVault/setup/novell-NDSserv-*.rpm"`
	isUpgradeReq=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$SUPPORTED_EDIR_VERSION'" }')

	if [ -z "$instRPMVersion" ]
	then

		echo "0"
		return
	fi

	if [ "$instRPMVersion" == "$RPMVersionToUpg" ]
	then

		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
       			echo "1"
     fi
     return
}

isIDMFOUpgRequired()
{
	 instRPMVersion=`rpm -qa --queryformat '%{version}' novell-DXMLfanoutagent`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDM/packages/fanout/novell-DXMLfanoutagent*.rpm"`
	isUpgradeReq=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$SUPPORTED_IDM_FO_VERSION'" }')

	if [ -z "$instRPMVersion" ]
	then
		echo "0"
		return
	fi

	if [ "$instRPMVersion" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	rpm -Uvh --test "${IDM_INSTALL_HOME}/IDM/packages/fanout/novell-DXMLfanoutagent*.rpm" &> /dev/null
	retCode=$?
	if [ $retCode -eq 0 ]
	then
		#Allow upgrade
		echo "1"
		return
	elif [ $retCode -eq 2 ]
	then
		#Installed version is newer than the one in ISO/zip
		isUpgradeReq=0
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed 
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isiManUpgRequired()
{
	 instRPMVersion=`rpm -qa --queryformat '%{version}' novell-imanager`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/iManager/packages/novell-imanager*.rpm"`
     isUpgradeReq=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instRPMVersion'"<"'$SUPPORTED_IMANAGER_VERSION'" }')

	if [ -z "$instRPMVersion" ]
	then
		echo "0"
		return
	fi

	if [ "$instRPMVersion" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed 
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isUAAppUpgReq()
{
     instAPPVersion=`UAAppVersion`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/user_application/packages/ua/netiq-userapp-*.rpm"`
     isUpgradeReq=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$SUPPORTED_APP_UA_VERSION'" }')

	if [ -z "$instAPPVersion" ]
	then
		echo "0"
		return
	fi

     RPMVersionToUpg=`echo "\"$RPMVersionToUpg\""`
	if [ "$instAPPVersion" == "$RPMVersionToUpg" ] || [ "\"$instAPPVersion\"" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed 
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isReportingAppUpgReq()
{
     instAPPVersion=`ReportingAppVersion`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/reporting/packages/netiq-IDMRPT*.rpm"`
     isUpgradeReq=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$SUPPORTED_APP_REPORT_VERSION'" }')

	if [ -z "$instAPPVersion" ]
	then
		echo "0"
		return
	fi

     RPMVersionToUpg=`echo "\"$RPMVersionToUpg\""`
	if [ "$instAPPVersion" == "$RPMVersionToUpg" ] || [ "\"$instAPPVersion\"" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isSSPRUpgReq()
{
     instAPPVersion=`rpm -qa --queryformat '%{version}' netiq-sspr`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/sspr/packages/netiq-sspr-*.rpm"`
     isUpgradeReq=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$SUPPORTED_SSPR_VERSION'" }')
	 if [ "$RPMVersionToUpg" == "" ]
	 then
	 	if [ "$instAPPVersion" != "" ]
		then
			echo "3"
			return
		fi
	 fi

	if [ -z "$instAPPVersion" ]
	then
		echo "0"
		return
	fi

     RPMVersionToUpg=`echo "\"$RPMVersionToUpg\""`
	if [ "$instAPPVersion" == "$RPMVersionToUpg" ] || [ "\"$instAPPVersion\"" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

isOSPUpgReq()
{
     instAPPVersion=`rpm -qa --queryformat '%{version}' netiq-osp`
	 RPMVersionToUpg=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/osp/packages/netiq-osp-*.rpm"`
     isUpgradeReq=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$RPMVersionToUpg'" }')
     isNotSupportedVersion=$(awk 'BEGIN{ print "'$instAPPVersion'"<"'$SUPPORTED_OSP_VERSION'" }')
	 if [ "$RPMVersionToUpg" == "" ]
	 then
	 	if [ "$instAPPVersion" != "" ]
		then
			echo "3"
			return
		fi
	 fi

	if [ -z "$instAPPVersion" ]
	then
		echo "0"
		return
	fi

     RPMVersionToUpg=`echo "\"$RPMVersionToUpg\""`
	if [ "$instAPPVersion" == "$RPMVersionToUpg" ] || [ "\"$instAPPVersion\"" == "$RPMVersionToUpg" ]
	then
		echo "3"
		return
	fi

	if [ $isUpgradeReq -eq 0 ]
	then
		# Latest version than the one found in ISO/zip is installed
		echo "4"
		return
	fi

     if [ $isUpgradeReq -eq 1 ]
     then
		if [ ! -z "$isNotSupportedVersion" ] && [ $isNotSupportedVersion -eq 1 ]
		then
       			echo "2"
		else
       			echo "1"
       	fi
     fi
     return
}

