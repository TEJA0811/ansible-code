#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

if [ ! -z "$debug" ] && [ "$debug" = 'y' ]
then
	set -x
fi
DIR=`dirname $0`

COMMON_PACKAGE_DIR=`pwd`/../common/packages
COMMON_RPM_LIST=


#################################################################
#
#   Install the common library packages
#   in: filename (absolute path) containing the list of common
#       library rpm's to be installed
#
#################################################################
install_common_libs()
{
    str1=`gettext install "Installing the required common library packages"`
    if [ -z "$2" ]
    then
      write_and_log "$str1" 
    else
      write_log "$str1" 
    fi
    deps_file=$1
    cat $deps_file | while read deps
    do
        PKGDIR=${COMMON_PACKAGE_DIR}/${deps}
        RPMLIST=${COMMON_PACKAGE_DIR}/${deps}/deps.list 
        #str1=`gettext install "Installing ... "`
        #write_and_log "$INSTR $str1 $deps"
        installrpm $PKGDIR $RPMLIST
        RC=$?
        if [ $RC -ne 0 ]
        then
            exit 1
        fi 
    done
    str1=`gettext install "Installed the common library packages succesfully."`
    write_log "$str1" 
}

#################################################################
#
#   Upgrade the common library packages
#   in: filename (absolute path) containing the list of common
#       library rpm's to be upgraded
#
#################################################################
upgrade_common_libs()
{
    str1=`gettext install "Upgrading common library packages."`
    write_and_log "$INSTR $str1" 
    COMMON_RPM_LIST=$1
    installrpm $COMMON_PACKAGE_DIR $COMMON_RPM_LIST 
    str1=`gettext install "Upgraded the common library packages succesfully."`
    write_and_log "$INSTR $str1" 
}


#This converts ldap dn to slash format
convert_slash_notation()
{
	container_ctx=$1
    IFS=',' read -ra CONT_DNs <<< "$container_ctx"
    COUNTER=${#CONT_DNs[@]}
    ITEM_MARKER=`expr $COUNTER - 1`
    ENTRY_DN=""
    for ((i=$ITEM_MARKER ; i >= 0; i--))
    do
       dn_item=${CONT_DNs[$i]}               
       IFS='=' read -ra LDAP_ITEMS <<< "$dn_item"
       LDAP_NAME="${LDAP_ITEMS[1]}"               
       ENTRY_DN="$ENTRY_DN\\$LDAP_NAME"
    done
   ENTRY_DN="${ENTRY_DN:1:${#ENTRY_DN}-1}"
   echo "$ENTRY_DN"
}

process_prompts()
{
local prod_name=$1
local prod_install=$2

eval "var_val=\$$prod_install"

    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        write_log "Configuring silent mode using silent property file: $FILE_SILENT_INSTALL"
        source $FILE_SILENT_INSTALL
#        eval "var_val=\$$prod_install"
        if [ "$prod_install" != "true" ]
        then
            write_log "Skippping configuration for $prod_name as it is not installed."
            exit
        fi
    else
       write_log "configure_interactive"
       source scripts/prompts.sh
       [ -f scripts/prompts_fr.sh ] && source scripts/prompts_fr.sh
    fi


}



#################################################################
#
#   Installs OSP components
#
#################################################################

install_osp()
{
    local CURR_DIR=`pwd`
    cd ${IDM_INSTALL_HOME}osp
    ./install.sh $*  
    cd $CURR_DIR


}


#################################################################
#
#   Configure OSP components
#
#################################################################

configure_osp()
{

    cd ${IDM_INSTALL_HOME}osp
    ./configure.sh $* 
    cd -
}

configure_sspr()
{

    cd ${IDM_INSTALL_HOME}sspr
    ./test.sh $*
    cd -
}

install_service_drivers()
{
    local OPT="$1"
    local ADM="$2"
    local PS="$3"
    local IP="$4:$5"
    local DS="$6"
    local CWD=`pwd`
    export ENVPWD=$PS

#    export LD_LIBRARY_PATH=${DESIGNER_HOME}/plugins/com.novell.core.iconeditor_4.0.0.201702032115/os/linux/x86_64:${DESIGNER_HOME}/plugins/com.novell.core.jars_4.0.0.201702032115/os/linux/x86_64:$LD_LIBRARY_PATH
    if [ "${OPT}" = "RPT" ]
    then
        str1=`gettext install "Deploying the Identity Reporting drivers. It may take a few minutes... "`
        write_and_log "$str1"
        cp driver_conf/NOVLIDMDCSB.properties ${DESIGNER_HOME}/ >>$LOG_FILE_NAME  2>&1
        cp driver_conf/NOVLIDMMSGWB.properties ${DESIGNER_HOME}/ >>$LOG_FILE_NAME  2>&1
        local dcs_prop_file=$DESIGNER_HOME/NOVLIDMDCSB.properties
        local msgw_prop_file=$DESIGNER_HOME/NOVLIDMMSGWB.properties

        search_and_replace "___ID_VAULT_HOST___"  $ID_VAULT_HOST "$msgw_prop_file"
        search_and_replace "___ID_VAULT_HOST___"  $ID_VAULT_HOST "$dcs_prop_file"
        search_and_replace "___ID_VAULT_LDAPS_PORT___"  $ID_VAULT_LDAPS_PORT "$dcs_prop_file"
        search_and_replace "___USER_CONTAINER___"  $USER_CONTAINER "$dcs_prop_file"
        search_and_replace "___ID_VAULT_ADMIN_LDAP___"  $ID_VAULT_ADMIN_LDAP "$dcs_prop_file"
        search_and_replace "___ID_VAULT_PWD___"  $ID_VAULT_PASSWORD "$dcs_prop_file"
        search_and_replace "___UA_ADMIN___"  $RPT_ADMIN "$dcs_prop_file"
        search_and_replace "___UA_ADMIN_PWD___"  $RPT_ADMIN_PWD "$dcs_prop_file"
        if [ "${KUBERNETES_ORCHESTRATION}" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]; then
          search_and_replace "___RPT_URL___"  $IDM_ACCESS_VIA_SINGLE_DOMAIN "$dcs_prop_file"
          search_and_replace "___RPT_PORT___"  "443" "$dcs_prop_file"
          search_and_replace "___SSO_URL___"  $IDM_ACCESS_VIA_SINGLE_DOMAIN "$dcs_prop_file"
          search_and_replace "___SSO_PORT___"  "443" "$dcs_prop_file"
        else
          search_and_replace "___RPT_URL___"  $RPT_SERVER_HOSTNAME "$dcs_prop_file"
          search_and_replace "___RPT_PORT___"  $RPT_SERVER_PORT "$dcs_prop_file"
          search_and_replace "___SSO_URL___"  $SSO_SERVER_HOST "$dcs_prop_file"
          search_and_replace "___SSO_PORT___"  $SSO_SERVER_SSL_PORT "$dcs_prop_file"
        fi
        search_and_replace "___SSO_PWD___" $RPT_SSO_SERVICE_PWD "$dcs_prop_file" 
        search_and_replace "___ID_VAULT_DRIVER_SET_DN___" "$ID_VAULT_DRIVER_SET,$ID_VAULT_DEPLOY_CTX" "$dcs_prop_file"
		
		
        
	    cd ${DESIGNER_HOME} >>$LOG_FILE_NAME
        # Bug workaround: headless truncates the log file during rpt driver deploy... 
        # Create a temp log file and use it for deployment logs
        TMP_LOG_FILE="${LOG_FILE_NAME}.deploylog"
        if [ $7 -eq 1 ]
        then
            #Advanced edition
            search_and_replace "___IS_AE___" "true" "$dcs_prop_file"
            PATH=${IDM_JRE_HOME}/bin:$PATH ${DESIGNER_HOME}/Designer -nosplash -nl en -application com.novell.idm.rcp.DesignerHeadless -command deployDriver -a "${ADM}" -w env:ENVPWD -s ${IP} -c "${DS}" -p "${DESIGNER_HOME}/packages/eclipse/plugins/" -b 3 -l $TMP_LOG_FILE -OL -data /tmp/idmdeploy >>$LOG_FILE_NAME  2>&1
        else
            #Standard edition
            search_and_replace "___IS_AE___" "false" "$dcs_prop_file"
            PATH=${IDM_JRE_HOME}/bin:$PATH ${DESIGNER_HOME}/Designer -nosplash -nl en -application com.novell.idm.rcp.DesignerHeadless -command deployDriver -a "${ADM}" -w env:ENVPWD -s ${IP} -c "${DS}" -p "${DESIGNER_HOME}/packages/eclipse/plugins/" -b 1 -l $TMP_LOG_FILE -OL -data /tmp/idmdeploy >>$LOG_FILE_NAME  2>&1
        fi
        #PATH=${IDM_JRE_HOME}/bin:$PATH ${DESIGNER_HOME}/Designer -nosplash -nl en -application com.novell.idm.rcp.DesignerHeadless -command deployDriver -a ${ADM} -w env:ENVPWD -s ${IP} -c ${DS} -p ${DESIGNER_HOME}/packages/eclipse/plugins/ -b 3 -l $TMP_LOG_FILE -OL -data /tmp/idmdeploy >>$LOG_FILE_NAME  2>&1
        cat ${TMP_LOG_FILE} >> ${LOG_FILE_NAME}
        rm ${TMP_LOG_FILE}
	    rm ${DESIGNER_HOME}/NOVLIDMMSGWB.properties
        rm ${DESIGNER_HOME}/NOVLIDMDCSB.properties
    else
        str1=`gettext install "Deploying the Identity Applications drivers. It may take a few minutes... "`
        write_and_log "$str1"
        cp driver_conf/NOVLRSERVB.properties ${DESIGNER_HOME}/ >>$LOG_FILE_NAME  2>&1
        cp driver_conf/NOVLUABASE.properties ${DESIGNER_HOME}/ >>$LOG_FILE_NAME  2>&1
        local rrsd_prop_file=$DESIGNER_HOME/NOVLRSERVB.properties
        local ua_prop_file=$DESIGNER_HOME/NOVLUABASE.properties
		
        local ua_url="https://${UA_SERVER_HOST}:${UA_SERVER_SSL_PORT}/${UA_APP_CTX}"
        if [ "${KUBERNETES_ORCHESTRATION}" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]; then
          ua_url="https://${IDM_ACCESS_VIA_SINGLE_DOMAIN}/${UA_APP_CTX}"
        fi

        search_and_replace "___UA_URL___"  $ua_url "$rrsd_prop_file"
        search_and_replace "___UA_ADMIN___"  $UA_ADMIN "$rrsd_prop_file"
        search_and_replace "___UA_ADMIN_PWD___" $UA_ADMIN_PWD "$rrsd_prop_file"
        local SLASH_FORMATED_ROOT_CONTAINER=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/dirxml_misc.jar com.netiq.installer.utils.DnConverter ${ROOT_CONTAINER} SLASH` >>$LOG_FILE_NAME  2>&1 

        search_and_replace "___ROOT_CONATINER___" ${SLASH_FORMATED_ROOT_CONTAINER} "$rrsd_prop_file"
         
        ID_VAULT_DRIVER_SET_DN="cn=$ID_VAULT_DRIVER_SET,$ID_VAULT_DEPLOY_CTX"
        #SLASH_DN="$(convert_slash_notation $ID_VAULT_DRIVER_SET_DN)"
        local SLASH_DN=`$IDM_JRE_HOME/bin/java -cp ${IDM_INSTALL_HOME}common/packages/utils/idm_install_utils.jar:${IDM_INSTALL_HOME}common/lib/dirxml_misc.jar com.netiq.installer.utils.DnConverter "${ID_VAULT_DRIVER_SET_DN}" SLASH` >>$LOG_FILE_NAME  2>&1 
        search_and_replace "___ID_VAULT_DRIVER_SET_DN___"  "$SLASH_DN" "$rrsd_prop_file"

        local ua_url="https://${UA_SERVER_HOST}"
        local ua_ssl_port="${UA_SERVER_SSL_PORT}"
        if [ "${KUBERNETES_ORCHESTRATION}" == "y" ] && [ "${KUBE_INGRESS_ENABLED}" == "true" ]; then
          ua_url="https://${IDM_ACCESS_VIA_SINGLE_DOMAIN}"
          ua_ssl_port="443"
        fi
        search_and_replace "___UA_ADMIN___"  $UA_ADMIN "$ua_prop_file"
        search_and_replace "___UA_URL___"  $ua_url "$ua_prop_file"
        search_and_replace "___TOMCAT_HTTPS_PORT___"  $ua_ssl_port "$ua_prop_file"
        search_and_replace "___UA_APP_CTX___"  $UA_APP_CTX "$ua_prop_file"
        search_and_replace "___UA_ADMIN_PWD___"  $UA_ADMIN_PWD "$ua_prop_file"
        

        cd ${DESIGNER_HOME} >>$LOG_FILE_NAME  
        # Bug workaround: headless truncates the log file during rpt driver deploy... 
        # Create a temp log file and use it for deployment logs
        TMP_LOG_FILE="${LOG_FILE_NAME}.deploylog"
        PATH=${IDM_JRE_HOME}/bin:$PATH ${DESIGNER_HOME}/Designer -nosplash -nl en -application com.novell.idm.rcp.DesignerHeadless -command deployDriver -a "${ADM}" -w env:ENVPWD -s ${IP} -c "${DS}" -p "${DESIGNER_HOME}/packages/eclipse/plugins/"  -b 12 -l $TMP_LOG_FILE -OL   -data /tmp/idmdeploy >>$LOG_FILE_NAME  2>&1
        cat ${TMP_LOG_FILE} >> ${LOG_FILE_NAME}
        rm ${TMP_LOG_FILE}
	if [ ! -z "$temporaryfileback" ] && [ "$temporaryfileback" == 'y' ]
	then
		cp ${DESIGNER_HOME}/NOVLRSERVB.properties /tmp
		cp ${DESIGNER_HOME}/NOVLUABASE.properties /tmp
	fi

        rm ${DESIGNER_HOME}/NOVLRSERVB.properties
        rm ${DESIGNER_HOME}/NOVLUABASE.properties
    fi
    export ENVPWD=""
    cd "${CWD}"
}

is_activemq_installed()
{
 IS_ACTIVEMQ_INSTALLED=0
 if [ -f "/etc/init.d/idmapps_activemq_init" ]
 then
   local INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2` 
   if [ -d "${INSTALLED_FOLDER_PATH}/activemq" ]
   then 
    IS_ACTIVEMQ_INSTALLED=1
   fi
 fi
 rpm -qi netiq-activemq &> /dev/null
 if [ $? -eq 0 ]
 then
 	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
	IS_ACTIVEMQ_INSTALLED=1
 fi
}
