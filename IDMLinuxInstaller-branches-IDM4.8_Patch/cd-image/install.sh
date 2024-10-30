#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. common/scripts/common_install_vars.sh
. common/scripts/commonlog.sh
. common/scripts/system_utils.sh
. common/scripts/license.sh 
. common/scripts/os_check.sh
. common/scripts/multi_select.sh
. common/scripts/ui_format.sh
. common/scripts/prompts.sh
. common/scripts/upgrade_check.sh
. common/scripts/components_version.sh
. common/scripts/common_install_error.sh
. common/scripts/locale.sh
. common/conf/global_paths.sh

if [ ! -f ${OES_file_tocheck} ]
then
	PRODUCTS=("IDM" "IDMRL" "IDMFO" "iManager"  "reporting"  "user_application")
else
	# For OES iManager update is done in their own channel hence blocking it
	PRODUCTS=("IDM" "IDMRL" "IDMFO" "iManager-blocked"  "reporting"  "user_application")
fi
PRODUCTS_DISP_NAME=("Identity Manager Engine" "Identity Manager Remote Loader Service" "Identity Manager Fanout Agent" "iManager Web Administration"  "Identity Reporting"  "Identity Applications")
INSTALL_PROD=("INSTALL_ENGINE" "INSTALL_RL" "INSTALL_FOA" "INSTALL_IMAN"  "INSTALL_REPORTING"  "INSTALL_UA")
userid=`id -u`
RLonlysetup
MIN_CPU=0
MIN_MEM=0
MIN_DISK_OPT=0
MIN_DISK_VAR=0
MIN_DISK_ETC=0
MIN_DISK_TMP=0
MIN_DISK_ROOT=0
IS_IDM_SYS_REQ_ACCOUNTED=0
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
PARAM_STR=
IS_UPGRADE=1
INSTALL_ONLY=0
UPGRADE_SUPPORTED=()
CURRENT_VERSION=()
OBSOLETE_INSTALL=()
IDM_INSTALL_HOME=`pwd`
initLocale
init_prompts common/conf/prompts.conf
UPGRADE_SUPPORTED_TXT=`gettext install "Upgrade is supported"`
UPGRADE_UNSUPPORTED_TXT=`gettext install "Upgrade is not supported"`
VER_IS_CURR_TXT=`gettext install "The current version is installed"`
NONROOTONLY_SUPPORTED_TXT=`gettext install "Non-root upgrade is supported if applicable"`
VER_TXT=`gettext install "Version "`
installCompleted=false
export skip_idv_cert_import=true
importgpgpackagesign

#DIRS_TO_CHECK=( "/opt/netiq"  "/var/opt/netiq" "/var" "/usr" "/etc" "/tmp"  "/")
#               1GB             5MB         1GB                 512MB  25MB 1MB     10MB                        10MB   512MB
#SPACE_NEEDED=( "107374182400000000"  "1073741824" "536870912" "26214400" "1048576" "10485760"  "536870912" )

install_product()
{
	PROD_NAME=$1
    COMPONENT=$2
    if [ "$PROD_NAME" = "IDMRL" ]
    then
        PROD_NAME=IDM
    fi
    if [ "$PROD_NAME" = "IDMFO" ]
    then
        PROD_NAME=IDM
    fi
    if [ ! -z "$promptsforRLonly" ] && [ "$promptsforRLonly" == "true" ]
    then
      COMPONENT=RL
    fi

    if [ $IS_UPGRADE -ne 1 ]
    then
        if [[ ( "$PROD_NAME" == "user_application" && "$IS_ADVANCED_EDITION" == "true" ) || ( "$PROD_NAME" == "reporting" ) ]]
        then
            cd osp
            ./install.sh ${PARAM_STR} -prod $PROD_NAME -wci -log ${LOG_FILE_NAME}
            cd $IDM_INSTALL_HOME     
            if [ "$PROD_NAME" == "user_application" ]
            then
	           cd sspr
	           ./install.sh ${PARAM_STR} -prod $PROD_NAME -wci -log ${LOG_FILE_NAME}
	           cd $IDM_INSTALL_HOME
    	       fi
        fi
    fi

    cd ${PROD_NAME}

    if [ "${COMPONENT}" != "" ]
    then
        ./install.sh ${PARAM_STR} -comp ${COMPONENT} -prod $PROD_NAME -wci -log ${LOG_FILE_NAME}
	RC=$?
	# if [ $RC -ne 0 ]
	# then
	 # exit 1
	# fi 
    else
       ./install.sh ${PARAM_STR} -prod $PROD_NAME -wci -log ${LOG_FILE_NAME}
	RC=$?
	# if [ $RC -ne 0 ]
	# then
	# exit 1
	# fi
    fi
    cd ..
}

check_oes_or_not()
{
  if [ ! -f ${OES_file_tocheck} ]
  then
    # 0 signifies that platform is non OES platform
    echo "0"
  else
    echo "1"
  fi
}

checkAndExitLicense()
{
    display_copyrights
}

add_sys_req()
{
    PROD_DIR=$1
    if [ "$PROD_DIR" = "IDMRL" ]
    then
        PROD_DIR=IDM
    fi
    if [ "$PROD_DIR" = "IDMFO" ]
    then
        PROD_DIR=IDM
    fi
        local CNT=`grep MIN_CPU "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_CPU=`expr $MIN_CPU + $CNT`

        CNT=`grep MIN_MEM "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_MEM=`expr $MIN_MEM + $CNT`

        CNT=`grep MIN_DISK_OPT "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_OPT=`expr $MIN_DISK_OPT + $CNT`

        CNT=`grep MIN_DISK_VAR "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_VAR=`expr $MIN_DISK_VAR + $CNT`

        CNT=`grep MIN_DISK_ETC "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_ETC=`expr $MIN_DISK_ETC + $CNT`

        CNT=`grep MIN_DISK_TMP "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_TMP=`expr $MIN_DISK_TMP + $CNT`

        CNT=`grep MIN_DISK_ROOT "${PROD_DIR}/sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_ROOT=`expr $MIN_DISK_ROOT + $CNT`
}

check_sys_req()
{
    #Check the Operating System
    verify_OSs
    
    #Check the CPU requirements
    checkAndExitCPU $MIN_CPU
    
    #Check the Memory requirement
    checkAndExitMemory $MIN_MEM
    
    #Check the Disk requirement
    DIRS_TO_CHECK=("/opt"  "/var" "/etc" "/tmp"  "/")
    SPACE_NEEDED=("$MIN_DISK_OPT" "$MIN_DISK_VAR" "$MIN_DISK_ETC" "$MIN_DISK_TMP" "$MIN_DISK_ROOT")
    checkAndExitDiskspace
}

create_common_menu()
{
	if [ $UNATTENDED_INSTALL -eq 0 ]
	then
    MENU_OPTIONS=()
    MENU_OPTIONS_DISPLAY=()
    UPGRADE_SUPPORTED=()
    CURRENT_VERSION=()
    OBSOLETE_INSTALL=()
    UP_TO_DATE=()
	fi
    
	if [ $UNATTENDED_INSTALL -eq 0 ]
	then
		local COUNT=${#PRODUCTS[@]}
	elif [ $UNATTENDED_INSTALL -eq 1 ]
	then
		local COUNT=${#MENU_OPTIONS[@]}
	fi
    
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
		if [ $UNATTENDED_INSTALL -eq 0 ]
		then
			PNAME=${PRODUCTS[i]}
		elif [ $UNATTENDED_INSTALL -eq 1 ]
		then
			PNAME=${MENU_OPTIONS[i]}
		fi
        if [ "$PNAME" = "IDMRL" ]
        then
            PNAME="IDM"
        fi
        if [ "$PNAME" = "IDMFO" ]
        then
            PNAME=IDM
        fi
        if [ -d "${PNAME}" ]
        then
            local isupg=0
            local ver=0
            if [ \( "${PRODUCTS[i]}" = "IDM" -a \( $UNATTENDED_INSTALL -eq 0 \) \) -o \( "${MENU_OPTIONS[i]}" = "IDM" -a \( $UNATTENDED_INSTALL -eq 1 \) \) ] && [ "$PNAME" = "IDM" ]
			then
                # IDM Engine
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
		  checkeDirExist
		  if [ -z ${NONROOT_IDVAULT_LOCATION} ] && [ "$EDIRVERSIONINST" == "" ]
		  then
			str1=$(gettext install "Non-root NDS folder location")
		  	str2=`gettext install "is missing."`
			write_and_log "$str1 $str2"
			write_and_log ""
			exit 1
		  fi
		  deduced_nonroot_path
		  rpmdbpath=`readlink -m $DEDUCED_NONROOT_IDVAULT_LOCATION/../../../rpm`
                  isupg=`isIDMUpgRequired $rpmdbpath`
		else
                  isupg=`isIDMUpgRequired`
		fi
                ver=`IDMVersion`
            elif [ \( "${PRODUCTS[i]}" = "IDMRL" -a \( $UNATTENDED_INSTALL -eq 0 \) \) -o \( "${MENU_OPTIONS[i]}" = "IDMRL" -a \( $UNATTENDED_INSTALL -eq 1 \) \) ] && [ "$PNAME" = "IDM" ]
            then
                # Remote Loader
                isupg=`isIDMRLUpgRequired`
                ver=`IDMRLVersion`
            elif [ \( "${PRODUCTS[i]}" = "IDMFO" -a \( $UNATTENDED_INSTALL -eq 0 \) \) -o \( "${MENU_OPTIONS[i]}" = "IDMFO" -a \( $UNATTENDED_INSTALL -eq 1 \) \) ] && [ "$PNAME" = "IDM" ]
            then
                # Fanout Agent
                isupg=`isIDMFOUpgRequired`
                ver=`IDMFOVersion`
            elif [ "$PNAME" = "iManager" ]
            then
                isupg=`isiManUpgRequired`
                ver=`iManagerVersion`
            elif [ "$PNAME" = "reporting" ]
            then
                isupg=`isReportingAppUpgReq`
                ver=`ReportingAppVersion`
            elif [ "$PNAME" = "user_application" ]
            then
                isupg=`isUAAppUpgReq`
                ver=`UAAppVersion`
            fi
	    if [ $UNATTENDED_INSTALL -eq 1 ] && [ ${isupg} -eq 0 ] && [ "$ver" == "" ]
	    then
	    	str=$(gettext install "is not available for patch upgrade.  Try installing")
		str2=$(gettext install "via the base installer.")
		write_and_log ""
		write_and_log "${MENU_OPTIONS[i]} $str ${MENU_OPTIONS[i]} $str2"
		write_and_log ""
		exit 1
	    fi
            if [ ${INSTALL_ONLY} -eq 1 ]
            then
                if [ ${isupg} -eq 0 ] && [ $UNATTENDED_INSTALL -eq 0 ]
                then
                    MENU_OPTIONS+=("${PRODUCTS[i]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]}")
                fi
            else
	    	if [ ${isupg} -eq 0 ] && [ $UNATTENDED_INSTALL -eq 0 ] && [ "${PRODUCTS[i]}" = "IDM" ] && [ $(check_oes_or_not) == "0" ]
		then
		    # This is for non-root install of engine
		    # ie., root user and engine not found but show it in options though
		    MENU_OPTIONS+=("${PRODUCTS[i]}")
		    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]} [${NONROOTONLY_SUPPORTED_TXT}]")
		fi
		if [ ${isupg} -eq 1 ] && [ $UNATTENDED_INSTALL -eq 0 ] && [ "${PRODUCTS[i]}" = "IDM" ] && [ $userid -ne 0 ] && [ $(check_oes_or_not) == "0" ]
		then
		    # This is for non-root install of engine
		    # ie., non-root user and root engine found but show it in options though
		    MENU_OPTIONS+=("${PRODUCTS[i]}")
		    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]} [${NONROOTONLY_SUPPORTED_TXT}]")
		fi
                if [ ${isupg} -eq 1 ] && [ $UNATTENDED_INSTALL -eq 0 ] && [ $userid -eq 0 ]
                then
                    MENU_OPTIONS+=("${PRODUCTS[i]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]} [${VER_TXT}${ver}] [${UPGRADE_SUPPORTED_TXT}]")
                    UPGRADE_SUPPORTED+=(${isupg})
                    CURRENT_VERSION+=(${ver})
                fi
                if [ ${isupg} -eq 2 ] && [ $userid -eq 0 ]
                then
					if [ $UNATTENDED_INSTALL -eq 0 ]
					then
						OBSOLETE_INSTALL+=("${PRODUCTS_DISP_NAME[i]} [${VER_TXT}${ver}] [${UPGRADE_UNSUPPORTED_TXT}]")
					elif [ $UNATTENDED_INSTALL -eq 1 ]
					then
						OBSOLETE_INSTALL+=("${MENU_OPTIONS_DISPLAY[i]} [${VER_TXT}${ver}] [${UPGRADE_UNSUPPORTED_TXT}]")
					fi
                fi
            fi
            if [ ${isupg} -eq 3 ] && [ $userid -eq 0 ]
            then
				if [ $UNATTENDED_INSTALL -eq 0 ]
				then
					UP_TO_DATE+=("${PRODUCTS_DISP_NAME[i]} [${VER_TXT}${ver}] [${VER_IS_CURR_TXT}]")
				elif [ $UNATTENDED_INSTALL -eq 1 ]
				then
					UP_TO_DATE+=("${MENU_OPTIONS[i]}")
				fi
            fi
        fi
    done
}

check_obsolete()
{
    local COUNT=${#OBSOLETE_INSTALL[@]}
    if [ ${COUNT} -gt 0 ]
    then
        OB_VER_TXT=`gettext install "Installer has detected one or more obsolete components of Identity Manager"`
        ERR_TXT=`gettext install "Upgrade/uninstall obsolete components before you proceed with the installation. Aborting installation..."`
        echo_sameline ""
        write_and_log "${OB_VER_TXT}"
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            val=`expr $i + 1`
            write_and_log "  $val ) ${OBSOLETE_INSTALL[i]}"
        done
        echo_sameline ""
        Check_install "${ERR_TXT}"
        echo_sameline ""
    fi
}

check_current()
{
    local COUNT=${#UP_TO_DATE[@]}
    if [ ${COUNT} -gt 0 ]
    then
        [ $UNATTENDED_INSTALL -eq 0 ] && CURR_VER_TXT=`gettext install "The following Identity Manager component(s) is/are already installed:"`
		[ $UNATTENDED_INSTALL -eq 1 ] && CURR_VER_TXT=`gettext install "The following Identity Manager component(s) is/are already upgraded:"`
        echo_sameline ""
        write_and_log "${CURR_VER_TXT}"
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            val=`expr $i + 1`
            write_and_log "  $val ) ${UP_TO_DATE[i]}"
			if [ $UNATTENDED_INSTALL -eq 1 ]
			then
				for arrayI in "${!MENU_OPTIONS[@]}"
				do
					if [[ ${MENU_OPTIONS[arrayI]} = "${UP_TO_DATE[i]}" ]]
					then
						unset 'MENU_OPTIONS[arrayI]'
						unset 'MENU_OPTIONS_DISPLAY[arrayI]'
					fi
				done
				MENU_OPTIONS=("${MENU_OPTIONS[@]}")
				MENU_OPTIONS_DISPLAY=("${MENU_OPTIONS_DISPLAY[@]}")
			fi
        done
		echo_sameline ""
    fi
}

check_inst_upg_opt()
{
    COUNT=${#MENU_OPTIONS[@]}
    if [ ${COUNT} -eq 0 ]
    then
        return
    fi
    set_is_upgrade
    echo_sameline ""
    UPG_DETECT_TXT=`gettext install "Installer has detected the following Identity Manager component(s) on the system for upgrade:"`
    echo_sameline ""
    write_and_log "${UPG_DETECT_TXT}"
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        val=`expr $i + 1`
        write_and_log "  $val ) ${MENU_OPTIONS_DISPLAY[i]}"
    done
    
    #  prompt - do you want to upgrade or install
    # if upgrade - go ahead with upgrade i.e set the flag
    # if install - continue with re-populating the options with only the install items
    
    if [ $UNATTENDED_INSTALL -eq 0 ]
    then
        #prompt_check_upgrade
	UPGRADE_IDM="y"
        if [ ${UPGRADE_IDM} == "y" ]
        then
            set_is_upgrade
            PARAM_STR="$PARAM_STR -u"
        else
            clear_is_upgrade
            INSTALL_ONLY=1
        fi
		if [ $IS_UPGRADE -eq 1 ]
		then
			LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idmupgrade.log
			set_log_file "${LOG_FILE_NAME}"
			cat $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
			rm -f $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
		else
			LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idminstall.log
			set_log_file "${LOG_FILE_NAME}"
			cat $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
			rm -f $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
		fi
        install_interactive
    else
		if [ ${UPGRADE_IDM} == "y" ]
        then
            set_is_upgrade
            PARAM_STR="$PARAM_STR -u"
        else
            clear_is_upgrade
            INSTALL_ONLY=1
        fi
		if [ $IS_UPGRADE -eq 1 ]
		then
			LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idmupgrade.log
			set_log_file "${LOG_FILE_NAME}"
			cat $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
			rm -f $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
		else
			LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idminstall.log
			set_log_file "${LOG_FILE_NAME}"
			cat $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
			rm -f $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
		fi
		install_silent
    fi
	installCompleted=true
}

check_and_upgrade()
{
    create_common_menu
    check_obsolete
    check_current
    check_inst_upg_opt
}

containsElement ()
{
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && echo 0 && return 0; done
        echo 1;return 1
}

prompt_idv_location()
{
    local idmselected=`containsElement "IDM" "${SELECTION[@]}"`
    if [ $idmselected -eq 1 ] && [ $UNATTENDED_INSTALL -eq 1 ]
    then
    	# Giving second change for silent non-root
    	idmselected=`containsElement "IDM" "${MENU_OPTIONS[@]}"`
    fi
    local isupg=`isIDMUpgRequired`
    if [ $idmselected -eq 0 ] && [ $isupg -eq 0 ]
    then
    	str=`gettext install "Enter the non-root Identity Manager Engine install location : "`
	error_filemsg=`gettext install "Entered non-root Identity Manager Engine location is wrong. Enter correct details"`
	error_filemsg2=`gettext install "Entered Identity Manager Engine location does not have rpm database available with the non-root idvault location. Enter correct details"`
	error_filemsg3=`gettext install "Entered Identity Manager Engine location does not have novell-DXMLengnx rpm installed in the non-root location. Enter correct details"`
	success_filemsg4=`gettext install "Identity Manager Engine version is up-to-date. Exiting."`
	error_filemsg5=`gettext install "Entered Identity Manager Engine location has unsupported version"`
	error_filemsg6=`gettext install "to upgrade"`
	version_information=`gettext install "Installed Identity Manager Engine version is"`
	prompt_ProceedConfirm=`gettext install "Do you want to proceed with the upgrade (y/n):"`
	proceeding_str=`gettext install "Proceeding with the upgrade"`
	stop_Upgrade=`gettext install "Exiting the upgrade"`
	fileTocheck=dxcmd
	if [ -z "${NONROOT_IDVAULT_LOCATION}" ] && [ $UNATTENDED_INSTALL -ne 1 ]
	then
		echo_sameline ""
		# interactive install
		while [ true ]
		do
			read -e -p "$str" dirTocheck
			fileLocation=`find "$dirTocheck" -iname "$fileTocheck" 2> /dev/null`
			ls "$fileLocation" &> /dev/null
			if [ $? -ne 0 ]
			then
				write_and_log "$error_filemsg"
				echo_sameline ""
				continue
			else
				dirTocheck=$(dirname `dirname $fileLocation`)
				NONROOT_IDVAULT_LOCATION=$dirTocheck
				rpmdbpath=`readlink -m $NONROOT_IDVAULT_LOCATION/../../../rpm`
				ls "$rpmdbpath" &> /dev/null
				if [ $? -ne 0 ]
				then
					write_and_log "$error_filemsg2"
					echo_sameline ""
					continue
				fi
				instRPMVersion=$(isIDMUpgRequired $rpmdbpath true)
				upgcode=$(isIDMUpgRequired $rpmdbpath)
				if [ $upgcode -eq 0 ]
				then
					write_and_log "$error_filemsg3"
					echo_sameline ""
					continue
				fi
				if [ $upgcode -eq 3 ]
				then
					write_and_log "$success_filemsg4"
					echo_sameline ""
					exit 0
				fi
				if [ $upgcode -eq 2 ]
				then
					write_and_log "$error_filemsg5 $instRPMVersion $error_filemsg6"
					echo_sameline ""
					exit 1
				fi
				if [ $upgcode -eq 1 ]
				then
				    echo_sameline ""
					write_and_log "$version_information $instRPMVersion"
					echo_sameline ""
					strmsg=`gettext install "Skipping IDVault upgrade check as OES platform detected."`
                    if [ $(check_oes_or_not) == "0" ]
                    then
                        prompt_idvault_update "non root"
	                else
	                    write_log "$strmsg"
	                fi
					if [ "$yesorno" == "no" ] || [ "$yesorno" == "n" ] || [ "$yesorno" == "N" ] || [ "$yesorno" == "No" ] || [ "$yesorno" == "NO" ] || [ "$yesorno" == "no" ]
                    then
                        write_and_log "$stop_Upgrade"
						echo_sameline ""
						exit 1
					else
					    write_and_log "$proceeding_str"
						echo_sameline ""
					fi
				fi
				break
			fi

		done
	else
		# silent install
		dirTocheck=${NONROOT_IDVAULT_LOCATION}
		fileLocation=`find "$dirTocheck" -iname "$fileTocheck" 2> /dev/null`
		ls "$fileLocation" &> /dev/null
		if [ $? -ne 0 ]
		then
			write_and_log "$error_filemsg"
			echo_sameline ""
			exit 1
		else
			dirTocheck=$(dirname `dirname $fileLocation`)
			NONROOT_IDVAULT_LOCATION=$dirTocheck
			export DEDUCED_NONROOT_IDVAULT_LOCATION=$dirTocheck
			rpmdbpath=`readlink -m $NONROOT_IDVAULT_LOCATION/../../../rpm`
			ls "$rpmdbpath" &> /dev/null
			if [ $? -ne 0 ]
			then
				write_and_log "$error_filemsg2"
				echo_sameline ""
				exit 1
			fi
			instRPMVersion=$(isIDMUpgRequired $rpmdbpath true)
			upgcode=$(isIDMUpgRequired $rpmdbpath)
			if [ $upgcode -eq 0 ]
			then
				write_and_log "$error_filemsg3"
				echo_sameline ""
				exit 1
			fi
			if [ $upgcode -eq 3 ]
			then
				write_and_log "$success_filemsg4"
				echo_sameline ""
				exit 0
			fi
			if [ $upgcode -eq 2 ]
			then
				write_and_log "$error_filemsg5 $instRPMVersion $error_filemsg6"
				echo_sameline ""
				exit 1
			fi
			if [ $upgcode -eq 1 ]
			then
				write_and_log "$version_information $instRPMVersion"
				echo_sameline ""
			fi
		fi
	fi
	save_prompt NONROOT_IDVAULT_LOCATION
    fi
}

displaywarningforiManager()
{
	msg1=$(gettext install "iManager Web Administration is found in the machine.")
	msg2=$(gettext install "This upgrade would break iManager Web Administration and hence it is recommended that you migrate iManager to a standalone server.")
	msg3=$(gettext install "This upgrade would break iManager Web Administration.")
	msg4=$(gettext install "For iManager to continue working in this environment, please refer to known issues section of the latest IDM release notes for more details on work-around.")
	msg5=$(gettext install "Do you wish to proceed? [y/n]:")
	msg6=$(gettext install "Exiting...")
	msg7=$(gettext install "Ensure setting the key IMANAGER_MIGRATION_PLANNED with value true if you wish to proceed.")
	rpm -qi novell-imanager &> /dev/null
	if [ $? -eq 0 ] && [ ! -f /etc/opt/netiq/idm/configure/imanager_migration_planned ]
	then
		#iManager found.  Need to enforce prompt for interactive install and a way to bypass with silent install
		if [ -z "$IMANAGER_MIGRATION_PLANNED" ] && [ $UNATTENDED_INSTALL -ne 1 ]
		then
			#Interactive install
			#User is prompted for confirming the migration of iManager
			write_and_log ""
			echo_sameline "${txtred}"
			write_and_log "$msg1 $msg2 $msg4"
			echo_sameline "${txtrst}"
			write_and_log ""
			read -e -p "$msg5" yesorno
			if [ "$yesorno" == "" ] || [ "$yesorno" == "no" ] || [ "$yesorno" == "n" ] || [ "$yesorno" == "N" ] || [ "$yesorno" == "No" ] || [ "$yesorno" == "NO" ] || [ "$yesorno" == "no" ]
			then
				write_and_log ""
				write_and_log "$msg6"
				write_and_log ""
				exit 1
			fi
			#Reaching here would mean that the documented steps for iManager to work has been handled
			if [ ! -d /etc/opt/netiq/idm/configure/ ]
			then
				mkdir -p /etc/opt/netiq/idm/configure/
			fi
			touch /etc/opt/netiq/idm/configure/imanager_migration_planned
		elif [ $UNATTENDED_INSTALL -eq 1 ]
		then
			#Silent install
			if [ ! -z "$IMANAGER_MIGRATION_PLANNED" ] && [ "$IMANAGER_MIGRATION_PLANNED" == "true" ]
			then
				#User has migrated iManager and hence we can proceed
				write_and_log ""
				write_and_log "$msg1 $msg2"
				write_and_log ""
			else
				#User has not migrated iManager and hence install/upgrade needs to be blocked
				write_and_log ""
				write_and_log "$msg1 $msg3"
				write_and_log "$msg4 $msg7"
				write_and_log "$msg6"
				write_and_log ""
				exit 1
			fi
		fi
	fi
}

prompt_idvault_update()
{
    if [ -z "$1" ]
	then
	idvupgradeCode=$(isIDVaultUpgRequired)
	else
        idvupgradeCode=$(isIDVaultUpgRequired $NONROOT_IDVAULT_LOCATION)
	fi
	msg1=$(gettext install "An upgrade is available for the Identity Vault.")
	msge1=$(gettext install "Do you want to upgrade Identity Manager components before Identity Vault upgrade? [n]:")
	idvaultsetupDIR=$(readlink -m ${IDM_INSTALL_HOME}/IDVault/setup)
	msg2=$(gettext install "To update Identity Vault, execute the following commands:")
	msg3=$(gettext install "Once Identity Vault is upgraded, launch the patch installer to upgrade other Identity Manager components.")
	msg4=$(gettext install "For skipping the update of Identity Vault set IDVAULT_SKIP_UPDATE to true")
	str14=`gettext install "Upgrade to Identity Vault"`
	str15=`gettext install "version or later to continue..."`
	if [ ! -z "$idvupgradeCode" ] && [ $idvupgradeCode -eq 1 ] && [ -z "$IDVAULT_SKIP_UPDATE" ] && [ $UNATTENDED_INSTALL -ne 1 ]
	then
		read -e -p "$msg1 $msge1" yesorno
		if [ "$yesorno" == "" ] || [ "$yesorno" == "no" ] || [ "$yesorno" == "n" ] || [ "$yesorno" == "N" ] || [ "$yesorno" == "No" ] || [ "$yesorno" == "NO" ] || [ "$yesorno" == "no" ]
		then
			write_and_log ""
			write_and_log "$msg2"
			write_and_log ""
			write_and_log " 1) cd $idvaultsetupDIR"
			write_and_log " 2) ./nds-install"
			write_and_log ""
			write_and_log "$msg3"
			write_and_log ""
			exit 1
		fi
	elif [ ! -z "$idvupgradeCode" ] && [ $idvupgradeCode -eq 1 ] && [ $UNATTENDED_INSTALL -eq 1 ]
	then
		if [ ! -z "$IDVAULT_SKIP_UPDATE" ] && [ "$IDVAULT_SKIP_UPDATE" == "true" ]
		then
			write_and_log ""
			write_and_log "$msg1 $str14 $SUPPORTED_EDIR_VERSION $str15"
			write_and_log ""
			write_and_log "$msg2"
			write_and_log " 1) cd $idvaultsetupDIR"
			write_and_log " 2) ./nds-install"
			write_and_log ""
		else
			write_and_log ""
			write_and_log "$msg1 $str14 $SUPPORTED_EDIR_VERSION $str15"
			write_and_log ""
			write_and_log "$msg2"
			write_and_log " 1) cd $idvaultsetupDIR"
			write_and_log " 2) ./nds-install"
			write_and_log ""
			write_and_log "$msg3"
			write_and_log ""
			write_and_log "$msg4"
			write_and_log ""
			exit 1
		fi
	fi
}

engine_conditions()
{
    	#Provides an option to exit/proceed installation of Identity Manager Engine when the Identity Manager Engine is not found but idvault is available
	checkAndExitIDMEngineInstall
	#Provides an option to exit/proceed installation of Identity Manager Engine when there is unsupported version of IDVault is found
	checkAndExitUnsupportedIDVault
}

apps_conditions()
{
    	instAPPVersion=`rpm -q --queryformat '%{version}' "netiq-userapp"`
	APPVersionIDM48="4.8.0"
	nginx48RPMBuildTime=1569591236
	instnginxRPMBuildTime=`rpm -q --queryformat '%{Buildtime}' "netiq-nginx"`
	checkeDirExist
	if [ "$instAPPVersion" == "$APPVersionIDM48" ] && [ "$nginx48RPMBuildTime" -ge "$instnginxRPMBuildTime" ] && [ "$EDIRVERSIONINST" != "" ]
	then
	    rpm -Uvh --test ${IDM_INSTALL_HOME}/common/packages/nginx/netiq-nginx-*rpm &> /dev/null
	    if [ $? -ne 0 ]
	    then
		str=`gettext install "netiq-nginx has not been updated to support netiq-openssl 102t and above"`
		echo_sameline ""
		echo_sameline "${txtred}"
	        write_and_log "$str"
		echo_sameline "${txtrst}"
		echo_sameline ""
		exit
	    fi
	fi
	if [ "$instAPPVersion" == "$APPVersionIDM48" ] && [ "$EDIRVERSIONINST" != "" ]
	then
	    #Provides an option to exit/proceed installation of Identity Applications when there is unsupported version of IDVault is found
	    checkAndExitUnsupportedIDVault
	fi
}

printnewrptURL()
{
	if [ -z "$JRE8CODE_BLOCK" ] && [ ! -z $setmessageprintforrpt ]
	then
		#For reporting only we should display the new access URL
		rpturlvalue=$(grep IDMRPT/oauth.html /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | awk -F'=' '{print $2}')
		messagestr1=`gettext install "Identity Reporting is accessible @ $rpturlvalue"`
		write_and_log "     $messagestr1"
	fi
}

install_silent()
{
	messageforoffcloudjre8
    strmsg=`gettext install "Skipping IDVault upgrade check as OES platform detected."`
    if [ $(check_oes_or_not) == "0" ]
    then
    	prompt_idvault_update
    else
    	write_log "$strmsg"
    fi
	echo_sameline ""
	str1=`gettext install "Refer log for more information at"`
	write_and_log "$str1 ${LOG_FILE_NAME}"
	echo_sameline ""
#    local COMP=`grep IDM_COMPONENTS ${FILE_SILENT_INSTALL} | cut -d '=' -f 2`
#    IFS=', ' read -r -a MENU_OPTIONS <<< "$COMP"
	MENU_OPTIONS=()
    MENU_OPTIONS_DISPLAY=()
    UPGRADE_SUPPORTED=()
    CURRENT_VERSION=()
    OBSOLETE_INSTALL=()
    UP_TO_DATE=()

    if [  -f "$FILE_SILENT_INSTALL" ]
    then
		grep -q '[^[:space:]]' $FILE_SILENT_INSTALL
		if [ $? -eq 1 ]
		then
			str1=`gettext install "Error: File %s is empty. Please choose a correct file"`
			str1=`printf "$str1" "$FILE_SILENT_INSTALL"`
			write_and_log "$str1"
        exit 1 
		fi
        source $FILE_SILENT_INSTALL

        local COUNT=${#PRODUCTS[@]}
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            eval "var_val=\$${INSTALL_PROD[i]}"
            if [ "${var_val}" == "true" ]
            then
                MENU_OPTIONS+=("${PRODUCTS[i]}")
                MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]}")
            fi
        done
    else
        str1=`gettext install "File not found: "`
        write_and_log "$str1 $FILE_SILENT_INSTALL"
        exit 1   
    fi
    
    if [ $UPGRADE_IDM == "y" ]
    then
        set_is_upgrade
        PARAM_STR="$PARAM_STR -u"
    fi
    if [ "$IS_ADVANCED_EDITION" == "true" ]
    then
    	PARAM_STR="$PARAM_STR -ad"
    elif [ "$IS_ADVANCED_EDITION" == "false" ]
    then
    	PARAM_STR="$PARAM_STR -sd"
    fi

    local COUNT=${#MENU_OPTIONS[@]}
    if ((${COUNT} != 1 ))
    then
    	str1=`gettext install "Choose only one component to upgrade.."`
	    write_and_log "${str1}"
	exit 1
    fi
	displaywarningforiManager
    if [ ! -z "$INSTALL_ENGINE" ] && [ "$INSTALL_ENGINE" == "true" ]
    then
    	engine_conditions
    fi
    if [ ! -z "$INSTALL_UA" ] && [ "$INSTALL_UA" == "true" ]
    then
    	apps_conditions
    fi
	if [ ! -z "$INSTALL_REPORTING" ] && [ "$INSTALL_REPORTING" == "true" ]
    then
    	#Reporting selected
		export setmessageprintforrpt=1
    fi
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        if [ "${MENU_OPTIONS[i]}" != "IDM" ] && [ "${MENU_OPTIONS[i]}" != "IDMRL" ] && [ "${MENU_OPTIONS[i]}" != "IDMFO" ]
        then
            add_sys_req ${MENU_OPTIONS[i]}
        else
            if [ $IS_IDM_SYS_REQ_ACCOUNTED -eq 0 ]
            then
                add_sys_req ${MENU_OPTIONS[i]}
                IS_IDM_SYS_REQ_ACCOUNTED=1
            fi
        fi
    done
    
    check_sys_req
	
	create_common_menu
	check_obsolete
	check_current
    
	local COUNT=${#MENU_OPTIONS[@]}
    
    if [ $IS_SYSTEM_CHECK_DONE -ne 1 ]
    then
        local result=`containsElement "IDM" "${MENU_OPTIONS[@]}"`
        if [ $result -eq 0 ]
        then
            checkPrerequisites "IDME"
            checkPrerequisites "IDV"
        fi
        result=`containsElement "IDMRL" "${MENU_OPTIONS[@]}"`
        if [ $result -eq 0 ]
        then
            checkPrerequisites "RL"
        fi
        result=`containsElement "iManager" "${MENU_OPTIONS[@]}"`
        if [ $result -eq 0 ]
        then
            checkPrerequisites "iManager"
        fi
        removePrerequisiteFile
    fi
    prompt_idv_location
    if [ ! -z "${NONROOT_IDVAULT_LOCATION}" ]
    then
    	prompt_idvault_update "non root"
    fi
	for (( i = 0 ; i < $COUNT ; i++ ))
    do
        if [ $IS_UPGRADE -eq 1 ]
        then
            str1=`gettext install "Upgrading :"`
        else
            str1=`gettext install "Installing :"`
        fi
        DT=`date`
	    echo_sameline "${txtylw}"
        write_and_log "###############################################################"
        echo_sameline "${txtrst}"
        write_and_log " 	   $str1 ${MENU_OPTIONS_DISPLAY[i]}"
        write_and_log " 	   $DT"
        echo_sameline "${txtylw}"
        write_and_log "###############################################################"
        write_and_log ""
	    echo_sameline "${txtrst}"
        local COMPONENT=
        if [ "${MENU_OPTIONS[i]}" = "IDM" ]
        then
            COMPONENT="ENGINE"
        elif [ "${MENU_OPTIONS[i]}" = "IDMRL" ]
        then
            COMPONENT="RL"
        elif [ "${MENU_OPTIONS[i]}" = "IDMFO" ]
        then
            COMPONENT="FOA"
        fi
		
        install_product ${MENU_OPTIONS[i]} ${COMPONENT}
		upgradefailed=0
		installfailed=0
        if [ $IS_UPGRADE -eq 1 ]
        then
			if [ $RC -ne 0 ]
			then
				str1=`gettext install "Aborted upgrade of : "`
				upgradefailed=1
			else
				str1=`gettext install "Completed upgrade of : "`
			fi
        else
			if [ $RC -ne 0 ]
			then
				str1=`gettext install "Aborted installation of : "`
				installfailed=1
		    else
				str1=`gettext install "Completed installation of : "`
			fi
        fi
        str2=`gettext install "Invoke 'configure.sh' to proceed with configuration."`
        
        DT=`date`
        echo_sameline "${txtylw}"
        write_and_log "###############################################################"
        echo_sameline "${txtrst}"
        write_and_log "     $str1 ${MENU_OPTIONS_DISPLAY[i]}"
        write_and_log "     $DT"
		printnewrptURL
        if [ $installfailed -eq 0 ] && [ $IS_UPGRADE -ne 1 ]
        then
	  if [ ! -z "$COMPONENT" ]
	  then
	    if [ "$COMPONENT" != "RL" ] && [ "$COMPONENT" != "FOA" ]
	    then
	      if [ -z "$promptsforRLonly" ]
	      then
                write_and_log ""
                write_and_log "     $str2"
	      fi
	    fi
	  else
	    write_and_log ""
	    write_and_log "     $str2"
	  fi
        fi
        echo_sameline "${txtylw}"
        write_and_log "###############################################################"
        write_and_log ""
        write_and_log ""
        echo_sameline "${txtrst}"
		if [ $installfailed -eq 1 ]
			then
				str1=`gettext install "Exiting due to a failure in the installation of %s"`
				str1=`printf "$str1" "${MENU_OPTIONS_DISPLAY[i]}"`
				echo_sameline "${txtred}"
				write_and_log " $str1"
				echo_sameline "${txtrst}"
				exit 1
		elif [ $upgradefailed -eq 1 ]
			then
				str1=`gettext install "Exiting due to a failure in the upgrade of %s"`
				str1=`printf "$str1" "${MENU_OPTIONS_DISPLAY[i]}"`
				echo_sameline "${txtred}"
				write_and_log " $str1"
				echo_sameline "${txtrst}"
				exit 1
            fi
    done
}

install_interactive()
{
	messageforoffcloudjre8	
    strmsg=`gettext install "Skipping IDVault upgrade check as OES platform detected."`
    if [ $(check_oes_or_not) == "0" ]
    then
    	prompt_idvault_update
    else
    	write_log "$strmsg"
    fi
	echo_sameline ""
	str1=`gettext install "Refer log for more information at"`
    echo_sameline "${txtgrn}"
	write_and_log "$str1 ${LOG_FILE_NAME}"
    echo_sameline "${txtrst}"
	echo_sameline ""
    RC1=$1
#    local COUNT=${#PRODUCTS[@]}
#    for (( i = 0 ; i < $COUNT ; i++ ))
#    do
#        PNAME=${PRODUCTS[i]}
#        if [ "$PNAME" = "IDMRL" ]
#        then
#            PNAME="IDM"
#        fi
#        if [ "$PNAME" = "IDMFO" ]
#        then
#            PNAME=IDM
#        fi
#        if [ -d "${PNAME}" ]
#        then
#            MENU_OPTIONS+=("${PRODUCTS[i]}")
#            MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]}")
#        fi
#    done
    
    # Do not recreate the menu when performing upgrade
    if [ $IS_UPGRADE -eq 0 ]
    then
        INSTALL_ONLY=1
        create_common_menu

		COUNT=${#MENU_OPTIONS[@]}
		if [ $COUNT -eq 0 ]
		then
			str1=`gettext install "No component(s) available for installation."`
			write_and_log "$str1"
			exit 1
		fi
        VAL="false"
        prompt_stand_advan

        if [ $VAL == "false" ]
        then
            unset 'MENU_OPTIONS[${#MENU_OPTIONS[@]}-1]'
            unset 'MENU_OPTIONS_DISPLAY[${#MENU_OPTIONS_DISPLAY[@]}-1]'
            IS_ADVANCED_EDITION="false"
			PARAM_STR="$PARAM_STR -sd"
        else
            IS_ADVANCED_EDITION="true"
            PARAM_STR="$PARAM_STR -ad"
        fi
    fi
    
    # In case there are multiple products, then
    # ask for use input for the products to install
    COUNT=${#MENU_OPTIONS[@]}
    if [ $COUNT -eq 0 ] && [ $IS_UPGRADE -eq 1 ]
    then
    	str1=`gettext install "No component(s) available for upgrade."`
	write_and_log "$str1"
	echo_sameline ""
    	exit 1
    fi
	displaywarningforiManager
    if [ $COUNT -gt 0 ]
    then
	    #write_and_log "=============================================================================="
        #echo_sameline "${txtylw}"
        if [ $IS_UPGRADE -eq 1 ]
        then
            echo_sameline "${txtrst}"
            MESSAGE=`gettext install "The following Identity Manager components are available for upgrade :"`
			OPT=true
			while ${OPT}
			do
				SELECTION=()
				SELECTION_DISPLAY=()
				MENU_USER_CHOICES=()
				get_user_input
				local COUNT=${#SELECTION[@]}
				if ((${COUNT} != 1 ))
				then
					str1=`gettext install "Choose only one component to upgrade.."`
					write_and_log "${str1}"
					continue
				else
					OPT=false
				fi
			done
        else
            MESSAGE=`gettext install "The following Identity Manager components are available for installation :"`
			get_user_input
        fi
        #echo_sameline "${txtrst}"
        #get_user_input

    
        COUNT=${#SELECTION[@]}
    
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            if [ "${SELECTION[i]}" != "IDM" ] && [ "${SELECTION[i]}" != "IDMRL" ] && [ "${SELECTION[i]}" != "IDMFO" ]
            then
                add_sys_req ${SELECTION[i]} >> $log_file
            else
                if [ $IS_IDM_SYS_REQ_ACCOUNTED -eq 0 ]
                then
                    add_sys_req ${SELECTION[i]}
                    IS_IDM_SYS_REQ_ACCOUNTED=1
                fi
            fi
        done
    else
        add_sys_req ${MENU_OPTIONS[0]}
	fi
    
    check_sys_req
	local SELECTION_DISPLAY_EDIT=${SELECTION_DISPLAY[0]}
	SELECTION_DISPLAY_EDIT=$(echo "${SELECTION_DISPLAY_EDIT}" | cut -d"[" -f1 | sed -e 's/ *$//g')
	if [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAME[0]}" ]
    then
    	engine_conditions
    fi
    if [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAME[5]}" ]
    then
    	apps_conditions
    fi
	if [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAME[4]}" ]
    then
    	#Reporting selected
		export setmessageprintforrpt=1
    fi
    
    COUNT=${#MENU_OPTIONS[@]}
    if [ $COUNT -gt 0 ]
    then
        COUNT=${#SELECTION[@]}
        if [ $IS_SYSTEM_CHECK_DONE -ne 1 ]
        then
            local result=`containsElement "IDM" "${SELECTION[@]}"`
            if [ $result -eq 0 ]
            then
                checkPrerequisites "IDME"
                checkPrerequisites "IDV"
            fi
            result=`containsElement "IDMRL" "${SELECTION[@]}"`
            if [ $result -eq 0 ]
            then
                checkPrerequisites "RL"
            fi
            result=`containsElement "iManager" "${SELECTION[@]}"`
            if [ $result -eq 0 ]
            then
                checkPrerequisites "iManager"
            fi
            removePrerequisiteFile
        fi
	prompt_idv_location
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            if [ $IS_UPGRADE -eq 1 ]
            then
                str1=`gettext install "Upgrading :"`
            else
                str1=`gettext install "Installing :"`
            fi
            DT=`date`
	        echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            echo_sameline "${txtrst}"
            write_and_log " 	$str1 ${SELECTION_DISPLAY[i]}"
            write_and_log " 	$DT"
            echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            write_and_log ""
 	        echo_sameline "${txtrst}"
            local COMPONENT=
			local SELECTION_DISPLAY_EDIT=${SELECTION_DISPLAY[i]}
			SELECTION_DISPLAY_EDIT=$(echo "${SELECTION_DISPLAY_EDIT}" | cut -d"[" -f1 | sed -e 's/ *$//g')
			if [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAME[0]}" ]
            then
                COMPONENT="ENGINE"
            elif [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAME[1]}" ]
            then
                COMPONENT="RL"
            elif [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAME[2]}" ]
            then
                COMPONENT="FOA"
            fi
            install_product ${SELECTION[i]} ${COMPONENT}
			upgradefailed=0
			installfailed=0
            if [ $IS_UPGRADE -eq 1 ]
            then
                if [ $RC -ne 0 ]
			    then
					str1=`gettext install "Aborted upgrade of : "`
					upgradefailed=1
				else
					str1=`gettext install "Completed upgrade of : "`
			    fi
            else
				if [ $RC -ne 0 ]
			    then
					str1=`gettext install "Aborted installation of : "`
					installfailed=1
				else
					str1=`gettext install "Completed installation of : "`
			    fi
            fi
            str2=`gettext install "Invoke 'configure.sh' to proceed with configuration."`
            DT=`date`
	        echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            echo_sameline "${txtrst}"
            write_and_log "     $str1 ${SELECTION_DISPLAY_EDIT}"
			printnewrptURL
            write_and_log "     $DT"
            if [ $installfailed -eq 0 ] && [ $IS_UPGRADE -ne 1 ]
            then
	      if [ ! -z "$COMPONENT" ]
	      then
	        if [ "$COMPONENT" != "RL" ] && [ "$COMPONENT" != "FOA" ]
	        then
	          if [ -z "$promptsforRLonly" ]
	          then
                    write_and_log ""
                    write_and_log "     $str2"
	          fi
	        fi
	      else
	        write_and_log ""
		write_and_log "     $str2"
              fi
	    fi
            echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            write_and_log ""
            write_and_log ""
	        echo_sameline "${txtrst}"
			if [ $installfailed -eq 1 ]
			then
				str1=`gettext install "Exiting due to a failure in the installation of %s"`
				str1=`printf "$str1" "${SELECTION_DISPLAY_EDIT}"`
				echo_sameline "${txtred}"
				write_and_log " $str1"
				echo_sameline "${txtrst}"
				exit 1
			elif [ $upgradefailed -eq 1 ]
			then
				str1=`gettext install "Exiting due to a failure in the upgrade of %s"`
				str1=`printf "$str1" "${SELECTION_DISPLAY_EDIT}"`
				echo_sameline "${txtred}"
				write_and_log " $str1"
				echo_sameline "${txtrst}"
				exit 1
            fi
        done
    else
		if [ "${MENU_OPTIONS[0]}" = "IDMRL" ]
		then
			COMPONENT="RL"
			install_product IDM ${COMPONENT}
		elif [ "${MENU_OPTIONS[0]}" = "IDMFO" ]
		then
			COMPONENT="FOA"
			install_product IDM ${COMPONENT}
		elif [ "${MENU_OPTIONS[0]}" = "IDM" ]
		then
			COMPONENT="ENGINE"
			install_product IDM ${COMPONENT}
		else
			install_product ${MENU_OPTIONS[0]}
		fi
    fi
}

install_stand_advan()
{
VAL="false"
    prompt_stand_advan
#    update_config_list

    if [ $VAL == "false" ]
    then
        unset 'MENU_OPTIONS[${#MENU_OPTIONS[@]}-1]'
        unset 'MENU_OPTIONS_DISPLAY[${#MENU_OPTIONS_DISPLAY[@]}-1]'
        IS_ADVANCED_EDITION="false"
		PARAM_STR="$PARAM_STR -sd"
    else
        IS_ADVANCED_EDITION="true"
        PARAM_STR="$PARAM_STR -ad"
    fi
 
}

configure_for_upgrade()
{
	if [ $IS_UPGRADE -eq 1 ]
	then
		cd $IDM_INSTALL_HOME
		#For upgrade typical configuration is sufficient hence setting it to run in typical mode
		#-typical stands for IS_ADVANCED_MODE="false"
		[ -f /etc/opt/netiq/idm/configure/IDM ] && IS_UPGRADE=1 UPGRADE_IDM="y" ./configure.sh "${*}" -wci -u -typical -log ${LOG_FILE_NAME}
	fi
}

install_products()
{
	installinput="${*}"
    parse_install_params $*
    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        if [ "${FILE_SILENT_INSTALL}" = "" ]
        then
            PARAM_STR="-slc -ssc -s -log ${LOG_FILE_NAME}"
        else
            PARAM_STR="-slc -ssc -s -f ${FILE_SILENT_INSTALL} -log ${LOG_FILE_NAME}"
        fi
    else
        PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME}"
    fi
    PWD=`pwd`
    IDM_INSTALL_HOME=$PWD
    DT=`date`
    write_and_log ""
    echo_sameline "${txtylw}"
    write_and_log "###############################################################"
    echo_sameline "${txtrst}"
    if [ $IS_UPGRADE -eq 1 ]
    then
	if [ -f "${IDM_INSTALL_HOME}/IDM/packages/engine/novell-DXMLengnx*.rpm" ]
	then
    		engineVersion=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDM/packages/engine/novell-DXMLengnx*.rpm"`
	else
		# RL only ISO; masking engineVersion with RL version
    		engineVersion=`rpm -qp --queryformat '%{version}' "${IDM_INSTALL_HOME}/IDM/packages/rl/x86_64/novell-DXMLrdxmlx-*.rpm"`
	fi
		mainReleaseVersion=`echo $engineVersion | cut -d"." -f1-2`
		servicePackVersion=`echo $engineVersion | cut -d"." -f3`
        str1=`gettext install "Identity Manager $mainReleaseVersion Service Pack $servicePackVersion"`
        str1="     $str1                     "
    else
        str1=`gettext install "Identity Manager Installation"`
        str1="     $str1                "
    fi
    write_and_log "${str1}"
    write_and_log "     $DT                 "
    echo_sameline "${txtylw}"
    write_and_log "###############################################################"
    write_and_log ""
    echo_sameline "${txtrst}"

    checkAndExitLicense
    
    check_and_upgrade
	[ $UNATTENDED_INSTALL -eq 1 ] && [ -f "${FILE_SILENT_INSTALL}" ] && source "${FILE_SILENT_INSTALL}"
	[ ! -z $NONROOT_IDVAULT_LOCATION ] && deduced_nonroot_path
	if [ "${UPGRADE_IDM}" == "y" ]
	then
		set_is_upgrade
		PARAM_STR="$PARAM_STR -u"
	else
		#clear_is_upgrade
		INSTALL_ONLY=1
	fi
	if [ $IS_UPGRADE -eq 0 ] && [ "${installCompleted}" == "false" ]
	then
		LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idminstall.log
		set_log_file "${LOG_FILE_NAME}"
		cat $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
		rm -f $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
			install_silent
		else
			install_interactive $RC1
		fi
	elif [ $IS_UPGRADE -eq 1 ] && [ "${installCompleted}" == "false" ]
	then
		LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idmupgrade.log
		set_log_file "${LOG_FILE_NAME}"
		cat $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
		rm -f $nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
		if [ $UNATTENDED_INSTALL -eq 1 ]
		then
			install_silent
		else
			install_interactive $RC1
		fi
	fi
	if [ $IS_UPGRADE -eq 1 ]
	then
		changeownershipofAppsAndACMQ
		RestrictAccess
	fi
    cd $PWD
	local COUNT=${#MENU_OPTIONS[@]}
	#[ ${COUNT} -gt 0 ] && configure_for_upgrade $installinput
	# str1=`gettext install "Refer log for more information at"`
	# write_and_log "$str1 ${LOG_FILE_NAME}"
}
if [ $userid -ne 0 ]
then
	nonroothomeDir=$(echo ~)
	if [ ! -d "$nonroothomeDir" ]
	then
		nonroothomeDir=/tmp
	fi
fi
LOG_FILE_NAME=$nonroothomeDir/var/opt/netiq/idm/log/idminstalltemp.log
rm -rf "${LOG_FILE_NAME}"
set_log_file "${LOG_FILE_NAME}"
cleanup_tmp
if [ -f "${INFO_FILENAME}" ]
then
    rm "${INFO_FILENAME}"
fi
foldername_space_check
OLD_IFS=$IFS
UPGRADE_IDM="y"
write_log "$SCRIPT_VERSION"
install_products $*
commonJREswitch
remove32bitJRE
removesslcryptolinks
fixssprconfigurationxml
IFS=$OLD_IFS
[ -d "${UNINSTALL_FILE_DIR}" ] && yes | cp -rpf uninstall.sh ${UNINSTALL_FILE_DIR}/ &> /dev/null
cleanup_tmp
