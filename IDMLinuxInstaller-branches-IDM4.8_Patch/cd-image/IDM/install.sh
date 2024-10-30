#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. ../common/conf/global_paths.sh
. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/install_common_libs.sh
. ../common/scripts/postgres.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/prompts.sh
. scripts/pre_install.sh
. ../common/scripts/upgrade_check.sh
. ../common/scripts/components_version.sh
. ../common/scripts/locale.sh

IDM_INSTALL_HOME=`pwd`/../
CONFIGURE_FILE=IDM
CONFIGURE_FILE_DISPLAY="Identity Manager Engine"
IDMVERSIONINST=
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
AVAILFORCONFIGURE=0
IDM_EDITION=advanced
UPGRADE_SUPPORTED=()
CURRENT_VERSION=()
OBSOLETE_INSTALL=()
userid=`id -u`

initLocale
UPGRADE_SUPPORTED_TXT=`gettext install "Upgrade is supported"`
UPGRADE_UNSUPPORTED_TXT=`gettext install "Upgrade is not supported"`
VER_IS_CURR_TXT=`gettext install "The current version is installed"`
VER_TXT=`gettext install "Version "`

PRODUCTSIDM=("IDM" "IDMRL" "IDMFO")
PRODUCTS_DISP_NAMEIDM=("Identity Manager Engine" "Identity Manager Remote Loader Service" "Identity Manager Fanout Agent")
INSTALL_PRODIDM=("INSTALL_ENGINE" "INSTALL_RL" "INSTALL_FOA")

checkIDMExist()
{
        IDMVERSIONINST=`rpm -qi novell-DXMLengnx 2>>$log_file | grep "Version" | awk '{print $3}'`
}

create_common_menu()
{
    MENU_OPTIONS=()
    MENU_OPTIONS_DISPLAY=()
    UPGRADE_SUPPORTED=()
    CURRENT_VERSION=()
    OBSOLETE_INSTALL=()
    UP_TO_DATE=()
    
    local COUNT=${#PRODUCTSIDM[@]}
    
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        PNAME=${PRODUCTSIDM[i]}
        if [ "$PNAME" = "IDMRL" ]
        then
            PNAME="IDM"
        fi
        if [ "$PNAME" = "IDMFO" ]
        then
            PNAME=IDM
        fi
        if [ -d "../${PNAME}" ]
        then
            local isupg=0
            local ver=0
            if [ "${PRODUCTSIDM[i]}" = "IDM" ] && [ "$PNAME" = "IDM" ]
            then
                # IDM Engine
                isupg=`isIDMUpgRequired`
                ver=`IDMVersion`
            elif [ "${PRODUCTSIDM[i]}" = "IDMRL" ] && [ "$PNAME" = "IDM" ]
            then
                # Remote Loader
                isupg=`isIDMRLUpgRequired`
                ver=`IDMRLVersion`
            elif [ "${PRODUCTSIDM[i]}" = "IDMFO" ] && [ "$PNAME" = "IDM" ]
            then
                # Fanout Agent
                isupg=`isIDMFOUpgRequired`
                ver=`IDMFOVersion`
            fi
            if [ ${INSTALL_ONLY} -eq 1 ]
            then
                if [ ${isupg} -eq 0 ]
                then
                    MENU_OPTIONS+=("${PRODUCTSIDM[i]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAMEIDM[i]}")
                fi
            else
                if [ ${isupg} -eq 1 ]
                then
                    MENU_OPTIONS+=("${PRODUCTSIDM[i]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAMEIDM[i]} [${VER_TXT}${ver}] [${UPGRADE_SUPPORTED_TXT}]")
                    UPGRADE_SUPPORTED+=(${isupg})
                    CURRENT_VERSION+=(${ver})
                fi
                if [ ${isupg} -eq 2 ]
                then
                    OBSOLETE_INSTALL+=("${PRODUCTS_DISP_NAMEIDM[i]} [${VER_TXT}${ver}] [${UPGRADE_UNSUPPORTED_TXT}]")
                fi
            fi
            if [ ${isupg} -eq 3 ]
            then
                UP_TO_DATE+=("${PRODUCTS_DISP_NAMEIDM[i]} [${VER_TXT}${ver}] [${VER_IS_CURR_TXT}]")
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
#               val=`echo " $i + 1" | bc`
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
        CURR_VER_TXT=`gettext install "The following Identity Manager component(s) is/are already installed:"`
        echo_sameline ""
        write_and_log "${CURR_VER_TXT}"
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
           val=`expr $i + 1`
            write_and_log "  $val ) ${UP_TO_DATE[i]}"
        done
        echo_sameline ""
    fi
}

configure_for_upgrade()
{
	if [ $IS_UPGRADE -eq 1 ]
	then
		cd $IDM_INSTALL_HOME/IDM
		#For upgrade typical configuration is sufficient hence setting it to run in typical mode
		#-typical stands for IS_ADVANCED_MODE="false"
		[ -f /etc/opt/netiq/idm/configure/IDM ] && IS_UPGRADE=1 ./configure.sh "${*}" -u -typical -log ${LOG_FILE_NAME}
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
        prompt_check_upgrade
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
			LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
			set_log_file "${LOG_FILE_NAME}"
			cat /var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
			rm -f /var/opt/netiq/idm/log/idminstalltemp.log
		else
			LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
			set_log_file "${LOG_FILE_NAME}"
			cat /var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
			rm -f /var/opt/netiq/idm/log/idminstalltemp.log
		fi
        install_interactiveIDM
    fi
	
	configure_for_upgrade
}

check_and_upgrade()
{
    create_common_menu
    check_obsolete
    check_current
    check_inst_upg_opt
}

handleAdvancedMode()
{

    if [ -z "$IS_ADVANCED_EDITION"  ] && [ "$UPGRADE_IDM" == "n" ]
    then
    VAL="false"
    prompt_stand_advan
    if [ $VAL == "false" ]
    then
        IS_ADVANCED_EDITION="false"
    else
        IS_ADVANCED_EDITION="true"
    fi
    fi
}


main()
{
	INVALIDEDIRVERSION=0
    init 
    #system_validate
    display_copyrights
    #handleAdvancedMode
	source_prompt_file
    
	install_common_libs `pwd`/common.deps #> $log_file 2>&1
	
    if [ $IS_ENGINE_INSTALL -eq 1 ]
    then
		AVAILFORCONFIGURE=0
		checkeDirExist
	#cat /var/opt/novell/eDirectory/log/nds-install.log >> $log_file
	if [ "$EDIRVERSIONINST" != "" ] || [ ! -z "$NONROOT_IDVAULT_LOCATION" ]
	then
		if ! grep -q "^idvadmin:*" /etc/group
		then
			[ $userid -eq 0 ] && groupadd -r idvadmin
		fi
			if [ -z "$NONROOT_IDVAULT_LOCATION" ]
    		then
    			#root install
				source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; ndsmanage stopall > /dev/null 2>&1
    		else
    			#non-root install
				PWDNONROOT=`pwd`
				cd ${DEDUCED_NONROOT_IDVAULT_LOCATION}/bin/
				source ndspath 1> /dev/null 2>&1; ndsmanage stopall > /dev/null 2>&1
				cd $PWDNONROOT
    		fi
		export NODEPS="--nodeps"
	        installrpm `pwd`/packages/common64 IDMcommon64.list
		export NODEPS=""
	        RPMFORCE="--force" NODEPS="--nodeps" installrpm `pwd`/packages/common64 IDMCEFInstrument.list
		installrpm `pwd`/packages/cefprocessor/x86_64 IDMCEFProcessorx.list
		rpm -qi novell-IDMCEFProcessor &> /dev/null
		if [ $? -eq 0 ]
		then
		  installrpm `pwd`/packages/cefprocessor/i386 IDMCEFProcessor.list
		fi
		installrpm `pwd`/packages/cefprocessor/noarch IDMCEFProcessorCommon.list
		if [ ! -f ${OES_file_tocheck} ]
		then
			installrpm `pwd`/packages/common IDMcommon.list
		fi
		installrpm `pwd`/packages/common IDMcommonlib.list
		if [ ! -f ${OES_file_tocheck} ]
		then
			RPMFORCE="--force" installrpm `pwd`/packages/engine IDMengine.list
            if [ -f `pwd`/../IDVault/setup/jre11/novell-edirectory-jclnt-*rpm ]
            then
			    RPMFORCE="--force" installrpm `pwd`/../IDVault/setup/jre11 jre11.list
            fi
		else
			RPMFORCE="--force" NODEPS="--nodeps" installrpm `pwd`/packages/engine IDMengine.list
		fi
		RPMFORCE="--force" installrpm `pwd`/packages/driver IDMdriver.list
		if [ -f /etc/opt/novell/eDirectory/conf/env_idm ] && [ -f ${OES_file_tocheck} ]
		then
			grep "LD_LIBRARY_PATH" /etc/opt/novell/eDirectory/conf/env_idm | grep eDir-exclusive
			if [ $? -ne 0 ]
			then
				sed -i "s#LD_LIBRARY_PATH=#LD_LIBRARY_PATH=//opt/novell/eDirectory/eDir-exclusive/lib64:#g" /etc/opt/novell/eDirectory/conf/env_idm
			fi
		fi
		if ! rpm -qa | grep -q novell-edirectory-expat
		then
		    if [ $userid -eq 0 ]
		    then
			cd /usr/lib64/
			if [ -f libexpat.so.1 ]
			then
				if [ ! -f libexpat.so.0 ]
				then
					ln -sf libexpat.so.1 libexpat.so.0
				fi
			else
				str=$(gettext install "Missing mandatory library :")
				write_and_log "$str /usr/lib64/libexpat.so.1"
			fi
			cd - &> /dev/null
		    fi
		fi
		if [ -z "$NONROOT_IDVAULT_LOCATION" ]
    		then
    			#root install
			source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; ndsmanage startall > /dev/null 2>&1
    		else
    			#non-root install
			PWDNONROOT=`pwd`
			deduced_nonroot_path
			cd ${DEDUCED_NONROOT_IDVAULT_LOCATION}/bin/
			#Copying contents of env_idm to pre_ndsd_start only in the case of RHEL
			grep "Red Hat" /etc/os-release &> /dev/null
			if [ $? -eq 0 ]
			then
				grep "jre/lib/amd64" ../sbin/pre_ndsd_start &> /dev/null
				if [ $? -ne 0 ]
				then
					if [ -f ../../../../etc/opt/novell/eDirectory/conf/env_idm ]
					then
						cat ../../../../etc/opt/novell/eDirectory/conf/env_idm >> ../sbin/pre_ndsd_start
					fi
				fi
			fi
			source ndspath 1> /dev/null 2>&1; ndsmanage startall > /dev/null 2>&1
			str1=`gettext install "Run idm-install-schema manually from"`
			#write_and_log "$str1 ${NONROOT_IDVAULT_LOCATION}/bin/"
			cd $PWDNONROOT
    		fi

	fi
	 # Create .idme 
     idmefile=$EDIR_INSTALL_DIR/.idme
     [ -f $idmefile ] && rm $idmefile
     [ "$IS_ADVANCED_EDITION" != "" ] && touch $idmefile &> /dev/null
     if [ "$IS_ADVANCED_EDITION" == "true" ]
     then
        if [ "$IS_ADVANCED_EDITION" != "" ]
	then
	  [ -f $idmefile ] && echo "3" >> $idmefile 
	fi
     else
        if [ "$IS_ADVANCED_EDITION" != "" ] 
	then
	  [ -f $idmefile ] && echo "2" >> $idmefile 
	fi
     fi
	
    elif [ $IS_RL_INSTALL -eq 1 ]
    then
	checkIDMExist
	removeobsoleterpms
        # Following is used install 32-bit RL
	if [ ! -z "$INSTALL_GLIBC32BIT" ] && [ "$INSTALL_GLIBC32BIT" == "true" ]
	then
	  installrpm `pwd`/packages/rl/i586 glibc32.list
	fi
	installrpm `pwd`/../common/packages/java IDMJRE32.list
	installrpm `pwd`/packages/rl/i586 rlwithEdir.list
	installrpm `pwd`/packages/OpenSSL/i586 openssl32.list	
	installrpm `pwd`/packages/OpenSSL/x86_64 openssl64.list
	installrpm `pwd`/packages/common IDMcommonlib.list
	installrpm `pwd`/packages/cefprocessor/i386 IDMCEFProcessor.list
        installrpm `pwd`/packages/cefprocessor/x86_64 IDMCEFProcessorx.list
	installrpm `pwd`/packages/cefprocessor/noarch IDMCEFProcessorCommon.list
	# Removing nici installation with RL - Defect#321039
	#installrpm `pwd`/packages/rl/x86_64 nici.list
    	if [ "$IDMVERSIONINST" != "" ]
	then
		installrpm `pwd`/packages/rl/x86_64 remoteLoader64.list
		#if [ "`rpm -qa | grep -i "novell-openssl" | wc -l`" == "1" ]
		#then
		#	installrpm `pwd`/packages/OpenSSL/x86_64 openssl64.list
		#fi 
	else
		export NODEPS="--nodeps"
	        installrpm `pwd`/packages/common64 IDMcommon64.list
		export NODEPS=""
		installrpm `pwd`/packages/rl/x86_64 remoteLoader64.list
		export NODEPS="--nodeps"
	        RPMFORCE="--force" NODEPS="--nodeps" installrpm `pwd`/packages/common64 IDMXDASlog.list
		if [ ! -f ${OES_file_tocheck} ]
		then
	        	installrpm `pwd`/packages/common64 IDMcommon64RL.list
	        	installrpm `pwd`/packages/common IDMcommon.list
		fi
		export NODEPS=""

		RPMFORCE="--force" installrpm `pwd`/packages/driver IDMdriver.list
	fi
	RPMFORCE="--force"
	installrpm `pwd`/packages/rl/i586 IDMcommon32RL.list
	installrpm `pwd`/packages/rl/i586 IDMcommon32.list
	RPMFORCE=
    elif [ $IS_FOA_INSTALL -eq 1 ]
    then
    		removeobsoleterpms
		installrpm $IDM_INSTALL_HOME/common/packages/activemq activemq_deps.list
		installrpm `pwd`/packages/common IDMcommonlib.list
		# Removing nici installation with FOA - Defect#321039
		#installrpm `pwd`/packages/rl/x86_64 nici.list
		installrpm `pwd`/packages/fanout IDMFanout.list
    else
        IS_ENGINE_INSTALL=1
    fi
    ## EDIRVERSIONINST variable will be set in install.sh of IDVault install.sh
    ## If EDIRVERSIONINST is valid then proceed with IDM install
    ## IDMengine.list should be updated with rpms required for engine
    ## IDMdriver.list should be updated with rpms required for driver
    ## IDMrl32.list should be updated with rpms required for RL 32-bit
    ## IDMrl64.list should be updated with rpms required for RL 64-bit
    ## RPM list should be updated with the order of dependency
    #if [ "$EDIRVERSIONINST" != "" ]
    #then
    #    installrpm `pwd`/packages/engine IDMengine.list
    #    installrpm `pwd`/packages/driver IDMdriver.list
    #fi
    
    if [ $AVAILFORCONFIGURE -eq 1 ] && [ "$INVALIDEDIRVERSION" != "1" ]
    then
        add_config_option $CONFIGURE_FILE
    fi
    mkdir -p ${UNINSTALL_FILE_DIR}/IDM &> /dev/null
    yes | cp -rpf ../common ${UNINSTALL_FILE_DIR}/ &> /dev/null
    yes | cp -rpf uninstall.sh ${UNINSTALL_FILE_DIR}/IDM &> /dev/null

    copyThirdPartyLicense
    removelibstdcbinariesNonRoot
}

add_sys_reqIDM()
{
        local CNT=`grep MIN_CPU "sys_req.sh" | cut -d '=' -f 2`
        MIN_CPU=`expr $MIN_CPU + $CNT`

        CNT=`grep MIN_MEM "sys_req.sh" | cut -d '=' -f 2`
        MIN_MEM=`expr $MIN_MEM + $CNT`

        CNT=`grep MIN_DISK_OPT "sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_OPT=`expr $MIN_DISK_OPT + $CNT`

        CNT=`grep MIN_DISK_VAR "sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_VAR=`expr $MIN_DISK_VAR + $CNT`

        CNT=`grep MIN_DISK_ETC "sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_ETC=`expr $MIN_DISK_ETC + $CNT`

        CNT=`grep MIN_DISK_TMP "sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_TMP=`expr $MIN_DISK_TMP + $CNT`

        CNT=`grep MIN_DISK_ROOT "sys_req.sh" | cut -d '=' -f 2`
        MIN_DISK_ROOT=`expr $MIN_DISK_ROOT + $CNT`
}

check_sys_reqIDM()
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

install_productIDM()
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
    
    if [ "${COMPONENT}" != "" ]
    then
        ./install.sh ${PARAM_STR} -comp ${COMPONENT} -prod $PROD_NAME -log ${LOG_FILE_NAME}
		RC=$?
		if [ $RC -ne 0 ]
		then
			exit 1
		fi 
    else
       ./install.sh ${PARAM_STR} -prod $PROD_NAME -log ${LOG_FILE_NAME}
		RC=$?
		if [ $RC -ne 0 ]
		then
			exit 1
		fi
    fi
}

containsElement ()
{
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && echo 0 && return 0; done
        echo 1;return 1
}

install_interactiveIDM()
{
    # local COUNT=${#PRODUCTSIDM[@]}
    # for (( i = 0 ; i < $COUNT ; i++ ))
    # do
        # PNAME=${PRODUCTSIDM[i]}
        # if [ "$PNAME" = "IDMRL" ]
        # then
            # PNAME="IDM"
        # fi
        # if [ "$PNAME" = "IDMFO" ]
        # then
            # PNAME=IDM
        # fi
        # if [ -d "../${PNAME}" ]
        # then
            # MENU_OPTIONS+=("${PRODUCTSIDM[i]}")
            # MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAMEIDM[i]}")
        # fi
    # done

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
	fi
    
    # In case there are multiple products, then
    # ask for use input for the products to install
    COUNT=${#MENU_OPTIONS[@]}
    if [ $COUNT -gt 0 ]
    then
	    #echo -e "\n=============================================================================="
        #echo "${txtylw}"
		if [ $IS_UPGRADE -eq 1 ]
        then
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
		#echo "${txtrst}"
        #get_user_input

    
        COUNT=${#SELECTION[@]}
    
        for (( i = 0 ; i < $COUNT ; i++ ))
        do
            if [ "${SELECTION[i]}" != "IDM" ] && [ "${SELECTION[i]}" != "IDMRL" ] && [ "${SELECTION[i]}" != "IDMFO" ]
            then
                add_sys_reqIDM ${SELECTION[i]} >> $log_file
            else
                if [ $IS_IDM_SYS_REQ_ACCOUNTED -eq 0 ]
                then
                    add_sys_reqIDM ${SELECTION[i]}
                    IS_IDM_SYS_REQ_ACCOUNTED=1
                fi
            fi
        done
    else
        add_sys_reqIDM ${MENU_OPTIONS[0]}
    fi
    
    check_sys_reqIDM
	local SELECTION_DISPLAY_EDIT=${SELECTION_DISPLAY[0]}
	SELECTION_DISPLAY_EDIT=$(echo "${SELECTION_DISPLAY_EDIT}" | cut -d"[" -f1 | sed -e 's/ *$//g')
    if [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAMEIDM[0]}" ]
    then
    	#Provides an option to exit/proceed installation of Identity Manager Engine when the Identity Manager Engine is not found but idvault is available
    	checkAndExitIDMEngineInstall
	#Provides an option to exit/proceed installation of Identity Manager Engine when there is unsupported version of IDVault is found
	checkAndExitUnsupportedIDVault
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
            removePrerequisiteFile
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
            write_and_log " 	$str1 ${SELECTION_DISPLAY[i]}"
            write_and_log " 	$DT"
            echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            write_and_log ""
 	        echo_sameline "${txtrst}"
            local COMPONENT=
			local SELECTION_DISPLAY_EDIT=${SELECTION_DISPLAY[i]}
			SELECTION_DISPLAY_EDIT=$(echo "${SELECTION_DISPLAY_EDIT}" | cut -d"[" -f1 | sed -e 's/ *$//g')
            if [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAMEIDM[0]}" ]
            then
                COMPONENT="ENGINE"
            elif [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAMEIDM[1]}" ]
            then
                COMPONENT="RL"
            elif [ "${SELECTION_DISPLAY_EDIT}" = "${PRODUCTS_DISP_NAMEIDM[2]}" ]
            then
                COMPONENT="FOA"
            fi
            install_productIDM ${SELECTION[i]} ${COMPONENT}
			if [ "$COMPONENT" == "ENGINE" ] && [ ! -f ${CONFIGURE_FILE_DIR}${CONFIGURE_FILE} ]
			then
				if [ $IS_UPGRADE -eq 1 ]
				then
					str1=`gettext install "Aborted upgrade of : "`
				else
					str1=`gettext install "Aborted installation of :"`
				fi
			else
				if [ $IS_UPGRADE -eq 1 ]
				then
					str1=`gettext install "Completed upgrade of :"`
				else
					str1=`gettext install "Completed installation of :"`
				fi
			fi
            DT=`date`
	        echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            echo_sameline "${txtrst}"
            write_and_log " 	$str1 ${SELECTION_DISPLAY_EDIT}"
            write_and_log " 	$DT"
            echo_sameline "${txtylw}"
            write_and_log "###############################################################"
            write_and_log ""
            write_and_log ""
	    echo_sameline "${txtrst}"
        done
    else
        if [ "${MENU_OPTIONS[0]}" = "IDMRL" ]
		then
			COMPONENT="RL"
			install_productIDM IDM ${COMPONENT}
		elif [ "${MENU_OPTIONS[0]}" = "IDMFO" ]
		then
			COMPONENT="FOA"
			install_productIDM IDM ${COMPONENT}
		elif [ "${MENU_OPTIONS[0]}" = "IDM" ]
		then
			COMPONENT="ENGINE"
			install_productIDM IDM ${COMPONENT}
		fi
    fi
}

checkAndExitLicense()
{
    display_copyrights
}

install_productsIDM()
{
    PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME}"
    DT=`date`
    write_and_log ""
    echo_sameline "${txtylw}"
    write_and_log "###############################################################"
    echo_sameline "${txtrst}"
    disp_str=`gettext install "Identity Manager Installation"`
    disp_str="            $disp_str                "
    write_and_log "$disp_str"
    write_and_log " 		$DT                 "
    echo_sameline "${txtylw}"
    write_and_log "###############################################################"
    write_and_log ""
    echo_sameline "${txtrst}"
    PWD=`pwd`
    IDM_INSTALL_HOME=$PWD/../
    
    checkAndExitLicense
	check_and_upgrade
	[ $UNATTENDED_INSTALL -eq 1 ] && [ -f "${FILE_SILENT_INSTALL}" ] && source "${FILE_SILENT_INSTALL}"
	if [ "${UPGRADE_IDM}" == "y" ]
	then
		set_is_upgrade
		PARAM_STR="$PARAM_STR -u"
	else
		clear_is_upgrade
		INSTALL_ONLY=1
	fi
	if [ $IS_UPGRADE -eq 1 ]
	then
		LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
		set_log_file "${LOG_FILE_NAME}"
		cat /var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
		rm -f /var/opt/netiq/idm/log/idminstalltemp.log
	else
		LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
		set_log_file "${LOG_FILE_NAME}"
		cat /var/opt/netiq/idm/log/idminstalltemp.log >> "${LOG_FILE_NAME}"
		rm -f /var/opt/netiq/idm/log/idminstalltemp.log
	fi
	install_interactiveIDM
    str1=`gettext install "Refer log for more information at"`
	write_and_log "$str1 ${LOG_FILE_NAME}"
}
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstalltemp.log
rm -rf "${LOG_FILE_NAME}"
set_log_file "${LOG_FILE_NAME}"
parse_install_params $*
if [ $IS_WRAPPER_CFG_INST -eq 0 ]
then
    cleanup_tmp
fi
foldername_space_check
exitIfnotRunfromWrapper

if [ "$#" == "0" ]
then
	MIN_CPU=0
	MIN_MEM=0
	MIN_DISK_OPT=0
	MIN_DISK_VAR=0
	MIN_DISK_ETC=0
	MIN_DISK_TMP=0
	MIN_DISK_ROOT=0
	IS_IDM_SYS_REQ_ACCOUNTED=0
	install_productsIDM
	
else
	main $*
fi
