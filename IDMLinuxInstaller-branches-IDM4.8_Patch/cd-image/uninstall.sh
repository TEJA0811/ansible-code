#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. common/scripts/installupgrpm.sh
. common/scripts/components_version.sh
. common/conf/global_variables.sh
. common/conf/global_paths.sh
. common/scripts/prompts.sh
. common/scripts/configureInput.sh
. common/scripts/common_install_vars.sh
. common/scripts/commonlog.sh
. common/scripts/config_utils.sh
. common/scripts/system_utils.sh
. common/scripts/install_common_libs.sh
. common/scripts/install_check.sh
. common/scripts/multi_select.sh
. common/scripts/common_install_error.sh
. common/scripts/ldap_utils.sh
. common/scripts/locale.sh

export IDM_INSTALL_HOME=`pwd`/
export WRAPPER_INSTALL_HOME=$IDM_INSTALL_HOME
initLocale

PRODUCTS=("IDM" "IDMRL" "IDMFO" "iManager" "user_application" "reporting")
PRODUCTS_DISP_NAME=("Identity Manager Engine" "Identity Manager Remote Loader Service" "Identity Manager Fanout Agent" "iManager Web Administration" "Identity Applications" "Identity Reporting")

LOG_FILE_NAME=/var/opt/netiq/idm/log/idmuninstall.log
PARAM_STR=
IS_ADVANCED_MODE=true
init_prompts ${UNINSTALL_FILE_DIR}common/conf/prompts.conf
source_prompt_file

UNIQUE_NAME=`uname -n |cut -d '.' -f 1 | sed -e "s/[^[:alnum:]]/_/g"`

containsElement ()
{
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && echo 0 && return 0; done
	echo 1;return 1
}

    uninstall_product()
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
    
    cd ${PROD_NAME}
    if [ "${COMPONENT}" != "" ]
    then
        ./uninstall.sh ${PARAM_STR} -comp ${COMPONENT} 2>> ${LOG_FILE_NAME}
    else
        ./uninstall.sh ${PARAM_STR} 2>> ${LOG_FILE_NAME}
    fi
    cd ..
}

update_uninstall_list()
{
    local COUNT=${#PRODUCTS[@]}
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        if [ -d "${UNINSTALL_FILE_DIR}/${PRODUCTS[i]}" ]
        then
            if [ "${PRODUCTS[i]}" = "IDM" ]
            then
                if [ -f "${UNINSTALL_FILE_DIR}/${PRODUCTS[i]}/IDMengine.list" ]
				then
                    MENU_OPTIONS+=("${PRODUCTS[0]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[0]}")
                fi
                if [ -f "${UNINSTALL_FILE_DIR}/${PRODUCTS[i]}/remoteLoader64.list" ]
				then
                    MENU_OPTIONS+=("${PRODUCTS[1]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[1]}")
                fi
                if [ -f "${UNINSTALL_FILE_DIR}/${PRODUCTS[i]}/IDMFanout.list" ]
				then
                    MENU_OPTIONS+=("${PRODUCTS[2]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[2]}")
                fi
			elif [  "${PRODUCTS[i]}" = "user_application" ]
			then
				if [ -f "${UNINSTALL_FILE_DIR}/${PRODUCTS[i]}/ua.list" ]
				then
                    MENU_OPTIONS+=("${PRODUCTS[4]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[4]}")
                fi
			elif [  "${PRODUCTS[i]}" = "reporting" ]
			then
				if [ -f "${UNINSTALL_FILE_DIR}/${PRODUCTS[i]}/reporting.list" ]
				then
                    MENU_OPTIONS+=("${PRODUCTS[5]}")
                    MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[5]}")
                fi
            else
			# iManager needs to be handled once we have install/uninstall script ready for it
                MENU_OPTIONS+=("${PRODUCTS[i]}")
                MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]}")
            fi
        fi
    done
	availableforuninstall=${#MENU_OPTIONS[@]}
	if [ $availableforuninstall -eq 1 ]
	then
		EligibleForFULLCLEANUP=true
	fi
}

uninstall_silent()
{
    local COMP=`grep IDM_COMPONENTS ${FILE_SILENT_INSTALL} | cut -d '=' -f 2`
    IFS=', ' read -r -a COMP_OPTIONS <<< "$COMP"
    local COUNT=${#COMP_OPTIONS[@]}
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        if [ "${COMP_OPTIONS[i]}" = "${PRODUCTS[i]}" ] && [ -d "${CONFIGURE_FILE_DIR}/${COMP_OPTIONS[i]}" ]
        then
            MENU_OPTIONS+=("${COMP_OPTIONS[i]}")
            MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]}")
        fi
    done

    local COUNT=${#MENU_OPTIONS[@]}
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        str1=`gettext install "Uninstalling :"`
        DT=`date`
        write_and_log "###############################################################"
        write_and_log " $str1 ${MENU_OPTIONS_DISPLAY[i]}"
        write_and_log " $DT"
        write_and_log "###############################################################"
        write_and_log ""
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
        uninstall_product ${MENU_OPTIONS[i]} ${COMPONENT}
        str1=`gettext install "Completed uninstallation of :"`
        DT=`date`
        write_and_log "###############################################################"
        write_and_log " $str1 ${MENU_OPTIONS_DISPLAY[i]}"
        write_and_log " $DT"
        write_and_log "###############################################################"
        write_and_log ""
        write_and_log ""
    done
}

uninstall_interactive()
{
    update_uninstall_list
    local COUNT=${#MENU_OPTIONS[@]}
    
    # In case there are multiple products, then
    # ask for use input for the products to uninstall
    COUNT=${#MENU_OPTIONS[@]}
    TOTALCOUNT=${COUNT}
    if [ $COUNT -gt 0 ]
    then
        MESSAGE=`gettext install "The following Identity Manager components are available for uninstallation : "`
        IS_UNINSTALL=1
        get_user_input
        
        COUNT=${#SELECTION[@]}
		if [ $COUNT -eq $availableforuninstall ]
		then
			# All components selected
			EligibleForFULLCLEANUP=true
			systemctl stop netiq-tomcat &> /dev/null
            systemctl stop netiq-postgresql &> /dev/null
            systemctl stop netiq-activemq &> /dev/null
            systemctl stop novell-tomcat9 &> /dev/null
            /opt/novell/tomcat9/bin/dtomcat9  stop &> /dev/null
		fi
		
		ENGINE_SELECT=`containsElement "IDM" "${SELECTION[@]}"`
		UA_SELECT=`containsElement "user_application" "${SELECTION[@]}"`
		RPT_SELECT=`containsElement "reporting" "${SELECTION[@]}"`
		rptver=`ReportingAppVersion`
		uaver=`UAAppVersion`
		
		if [ $ENGINE_SELECT -eq 0 ]
		then
			if [ "$rptver" != "" ] && [ "$uaver" != "" ] && [ $UA_SELECT -eq 1 ] && [ $RPT_SELECT -eq 1 ]
			then
				checkAndProceedUNInstall "userappANDreporting" "Identity Manager Engine"
			elif [ "$uaver" != "" ] && [ $UA_SELECT -eq 1 ]
			then
				checkAndProceedUNInstall "userapp" "Identity Manager Engine"
			elif [ "$rptver" != "" ] && [ $RPT_SELECT -eq 1 ]
			then
				checkAndProceedUNInstall "reporting" "Identity Manager Engine"
			fi
		fi
		
		if [ $UA_SELECT -eq 0 ]
		then
			if [ "$rptver" != "" ] && [ $RPT_SELECT -eq 1 ]
			then
				checkAndProceedUNInstall "reporting" "User Application"
			fi
		fi
		
		for (( i = 0 ; i < $COUNT ; i++ ))
        do
            local COMPONENT=
            if [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAME[0]}" ]
            then
				PROMPT_SAVE="false"
				userid=`id -u`
				if [ -z "$ID_VAULT_TREENAME" -o -z "$ID_VAULT_ADMIN" -o -z "$ID_VAULT_PASSWORD" ] && [ -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
				then
				    str1=`gettext install "Proceeding with the uninstallation of IDVault and Engine"`
	                str2=`gettext install "Proceeding with the uninstallation of Engine"`
                    if [ ! -f /etc/OES-brand ]
                    then
	                    prompt "UNINSTALL_IDVAULT" - "y/n"
	                fi
	                if [[ $UNINSTALL_IDVAULT == "Y" || $UNINSTALL_IDVAULT == "y" ]]; then
	                    echo_sameline "${txtylw}"
                        write_and_log "$str1"
                        echo_sameline "${txtrst}"
                        CHECK_ndslogin=true
					    while ${CHECK_ndslogin}
					    do
						    prompt "ID_VAULT_TREENAME" ${UNIQUE_NAME}_tree
						    prompt "ID_VAULT_ADMIN_LDAP"
						    convert_dot_notation ${ID_VAULT_ADMIN_LDAP}
						    prompt "ID_VAULT_ADMIN" $RET
						    prompt_pwd "ID_VAULT_PASSWORD"
						    source /opt/novell/eDirectory/bin/ndspath 1> /dev/null 2>&1; /opt/novell/eDirectory/bin/ndslogin -t ${ID_VAULT_TREENAME} ${ID_VAULT_ADMIN} -p ${ID_VAULT_PASSWORD} &> /dev/null
						    RC=$?
						    if [ $RC -ne 0 ]
						    then
						    	str1=`gettext install "Entered credentials are incorrect.  Enter the credentials again."`
						    	write_and_log "${str1}"
						    else
						    	CHECK_ndslogin=false
						    fi
					    done
					    save_prompt "ID_VAULT_TREENAME"
					    save_prompt "ID_VAULT_ADMIN"
					    save_prompt "ID_VAULT_PASSWORD"
                    else
                        echo_sameline "${txtylw}"
                        write_and_log "$str2"
                        echo_sameline "${txtrst}"
                    fi
                    save_prompt "UNINSTALL_IDVAULT"
				fi
            fi
        done
		
		for (( i = 0 ; i < $COUNT ; i++ ))
        do
	    IDM_INSTALL_HOME=$WRAPPER_INSTALL_HOME
	    initLocale
            str1=`gettext install "Performing uninstallation of:"`
            DT=`date`
            write_and_log "###############################################################"
            write_and_log " $str1 ${SELECTION_DISPLAY[i]}"
            write_and_log " $DT"
            write_and_log "###############################################################"
            write_and_log ""
            local COMPONENT=
            if [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAME[0]}" ]
            then
                COMPONENT="ENGINE"
            elif [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAME[1]}" ]
            then
                COMPONENT="RL"
            elif [ "${SELECTION_DISPLAY[i]}" = "${PRODUCTS_DISP_NAME[2]}" ]
            then
                COMPONENT="FOA"
            fi
            uninstall_product ${SELECTION[i]} ${COMPONENT}
	    IDM_INSTALL_HOME=$WRAPPER_INSTALL_HOME
	    initLocale
            str1=`gettext install "Completed uninstallation of:"`
            DT=`date`
            write_and_log "###############################################################"
            write_and_log " $str1 ${SELECTION_DISPLAY[i]}"
            write_and_log " $DT"
            write_and_log "###############################################################"
            write_and_log ""
            write_and_log ""
        done
    fi

    if [ $TOTALCOUNT = $COUNT ]
    then
        uninstall_product "common"
    fi

}

uninstall_products()
{
    parse_install_params $*
    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        if [ "${FILE_SILENT_INSTALL}" = "" ]
        then
            PARAM_STR="-s -log ${LOG_FILE_NAME}"
        else
            PARAM_STR="-s -f ${FILE_SILENT_INSTALL} -log ${LOG_FILE_NAME}"
        fi
    else
        PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME}"
    fi
    DT=`date`
    write_and_log "###############################################################"
    disp_str=`gettext install " Identity Manager uninstallation "`
    write_and_log "$disp_str"
    write_and_log " $DT"
    write_and_log "###############################################################"
    write_and_log ""
    PWD=`pwd`
    
    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        uninstall_silent
    else
        uninstall_interactive
    fi
    
    cd $PWD
}

set_log_file "${LOG_FILE_NAME}"
OLD_IFS=$IFS
write_log "$SCRIPT_VERSION"
uninstall_products $*
IFS=$OLD_IFS
rptver=`ReportingAppVersion`
uaver=`UAAppVersion`
imanver=`iManagerVersion`
# imanver to be added
if [ "$rptver" == "" ] && [ "$uaver" == "" ]
then
	[ -f /etc/init.d/netiq-postgresql ] && systemctl stop netiq-postgresql &> /dev/null
	[ -f /etc/init.d/netiq-tomcat ] && systemctl stop netiq-tomcat &> /dev/null
	rpm -e `rpm -qa | grep netiq-tomcatconfig-[0-9]` &> /dev/null
	rpm -e `rpm -qa | grep netiq-tomcat-[0-9]` &> /dev/null
	[ -d ../sspr ] && [ -f ../sspr/sspr.list ] && cd ../sspr && ./uninstall.sh && cd -
	[ -d ../osp ] && [ -f ../osp/osp.list ] && cd ../osp && ./uninstall.sh && cd -
	[ -f /opt/netiq/common/postgre/uninstall-postgresql ] && /opt/netiq/common/postgre/uninstall-postgresql &> /dev/null
	uninstallrpm "common/packages/postgres/" deps.list
fi


if [ "$EligibleForFULLCLEANUP" ]
then
    if [[ "$UNINSTALL_IDVAULT" == "Y" || "$UNINSTALL_IDVAULT" == "y" ]]
    then
    uninstallrpm IDM IDMCEFProcessorx.list	
    uninstallrpm IDM IDMCEFProcessor.list
    uninstallrpm IDM IDMCEFProcessorCommon.list
    uninstallrpm "common/packages/platform_agent/" deps.list
	rpm -e `rpm -qa | grep novell-openssl-[0-9]` &> /dev/null
	rpm -e `rpm -qa | grep netiq-openssl-[0-9]` &> /dev/null
	rpm -e --nodeps `rpm -qa | grep nici64` &> /dev/null
	rpm -e --nodeps novell-NOVLsubag-* &> /dev/null
	rpm -e --nodeps novell-edirectory-gperftools-* &> /dev/null
	rpm -e --nodeps novell-edirectory-xdaslog-32bit-* &> /dev/null
	rpm -e --nodeps novell-base-* &> /dev/null
	rpm -e --nodeps netiq-zoomdb-* &> /dev/null
        rpm -e --nodeps novell-libstdc++6-* &> /dev/null
	rpm -e --nodeps novell-libstdc++6-32bit-* &> /dev/null
    rpm -e --nodeps novell-edirectory-expat-32bit-* &> /dev/null
	rm -rf /opt/netiq/common
	rm -rf /opt/novell/{dirxml,eDirectory,lib64,man,lib}
	rm -rf /opt/novell/naudit
	rm -rf /var/opt/novell/naudit
	rm -rf /etc/logevent.conf
	rm -rf /var/opt/novell/eDirectory
	rm -rf /etc/opt/novell/eDirectory
        [ ! -f ${OES_file_tocheck} ] && rm -rf /opt/novell/{iManager,tomcat9}
	[ ! -f ${OES_file_tocheck} ] && rm -rf /var/opt/novell/{Uninstaller,iManager,nici,novlwww,tomcat9}
	[ ! -f ${OES_file_tocheck} ] && rm -rf /etc/opt/novell/{iManager,nici64.cfg,tomcat9}
	fi
    uninstallrpm iManager iManager.list
	rpm -e --nodeps netiq-idmtomcat-* &> /dev/null
	rm -rf /etc/systemd/system/netiq-activemq.service
	rm -rf /etc/systemd/system/netiq-postgresql.service
	rm -rf /etc/systemd/system/netiq-tomcat.service
	rm -rf /etc/systemd/system/netiq-nginx.service
	[ -f /etc/init.d/netiq-activemq ] && systemctl stop netiq-activemq &> /dev/null
	uninstallrpm "common/packages/java/" deps.list
	uninstallrpm "common/packages/activemq/" deps.list
	rpm -e --nodeps netiq-jrex* &> /dev/null
	rm -rf /opt/netiq/idm
	rm -rf /var/opt/netiq/
	rm -rf /etc/opt/netiq/idm
fi

rm -rf ${IDM_TEMP}

