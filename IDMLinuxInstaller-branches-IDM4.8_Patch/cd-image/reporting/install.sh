#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

IDM_INSTALL_HOME=`pwd`/../
CONFIGURE_FILE=reporting

. ../common/scripts/common_install_vars.sh
. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/license.sh 
. ../common/scripts/system_utils.sh
. ../common/scripts/os_check.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/install_common_libs.sh
. ../common/scripts/jre.sh
. ../common/scripts/tomcat.sh
. ../common/scripts/postgres.sh
. ../common/scripts/activemq.sh
. ../common/scripts/platform_agent.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/prompts.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/audit.sh
. ../common/scripts/ism_cfg_util.sh
. ../common/scripts/components_version.sh
. ../osp/scripts/osp_configure.sh
. ../osp/osp_pre_upgrade.sh
. ../osp/osp_post_upgrade.sh
. ../osp/scripts/merge_cust_loc.sh
. ../common/scripts/locale.sh
. ../common/scripts/database_utils.sh
. scripts/pre_install.sh
. scripts/rpt_upgrade.sh
. scripts/rpt_configure.sh
. conf/global_paths.sh
. ./pre_upgrade.sh
. ./post_upgrade.sh

CONFIGURE_FILE_DISPLAY="Identity Reporting"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
initLocale

main()
{
    parse_install_params $*
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        cleanup_tmp
    fi
    init
    foldername_space_check
    exitIfnotRunfromWrapper
    system_validate
    display_copyrights
    write_and_log ""
    write_and_log ""
    
    IS_UA_UPGRADED=0
    if [ $IS_UPGRADE -eq 1 ]
    then
        isUAUpgraded
        IS_UA_UPGRADED=$?
    fi

    is_activemq_installed
    if [ $IS_UPGRADE -eq 1 ]
    then
        IS_OSP_EXIST="false"
        if [ -f ${INSTALLED_FOLDER_PATH}/tomcat/webapps/osp.war ]
        then
          IS_OSP_EXIST="true"
        fi
        if [ $IS_UA_UPGRADED -eq 0 ]
        then
            install_common_libs `pwd`/java.deps
        fi
        LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
	    IS_ADVANCED_MODE="true"
        #init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf
        #process_prompts "Identity Applications" $OSP_INSTALL_FOLDER
        #source ${IDM_INSTALL_HOME}/reporting/pre_upgrade.sh
	   if [ -f /opt/rptcon_upgrade.properties ]
	   then
	       rm /opt/rptcon_upgrade.properties
	       touch /opt/rptcon_upgrade.properties 
        else
	       touch /opt/rptcon_upgrade.properties 
	   fi
	   rpm -qi netiq-tomcatconfig &> /dev/null
	   if [ $? -eq 0 ]
	   then
	   	INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
	   else
	   	INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2`
	   fi
	   #readconfigpropertiesfordbconn
	   if [ -f /opt/rptcon_upgrade.properties ]
	   then
	       sed -i 's#\\##g' /opt/rptcon_upgrade.properties
	       source /opt/rptcon_upgrade.properties
            if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "postgres" ]
            then
                DB_TYPE="PostgreSQL"
            elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
            then
                DB_TYPE="Oracle"
            elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
            then
                DB_TYPE="SQL Server"
            fi
	    #Not verifying db connection with patch
            #verify_db_connection ${RPT_DATABASE_USER} ${RPT_DATABASE_PASSWORD} ${RPT_DATABASE_CONNECTION_URL} ${DB_TYPE} ${RPT_DATABASE_JDBC_DRIVER_JAR}
            DB_CONN_RET=0

            if [ $DB_CONN_RET -eq 1 ]
            then
	           disp_str=`gettext install "Connection to database failed. Check database is running or parameters provided is valid. Run upgrade after correcting problem."`
		      write_and_log "$disp_str"
                exit
            else
		      disp_str=`gettext install "Database connection successful."`
			# write_and_log "$disp_str"
            fi
	   fi
	   reporting_pre_upgrade
    fi


    if [ $IS_UPGRADE -ne 1 ]
    then
        #Setup designer..
        strerr=`gettext install "Headless Desiner Installation Failed: Check Logs for More Details"`
        ${IDM_INSTALL_HOME}/designer/install.sh ${*}
        check_errs $? $strerr
        RET=$?
        check_return_value $RET
    fi
    
	#install OSP
	if [ $IS_WRAPPER_CFG_INST -eq 0 ]
	then
		if [[ ( "$RPT_OSP_INSTALLED" == "y" && "$IS_UPGRADE" -eq 1 && $IS_UA_UPGRADED -eq 0 ) || ( "$IS_UPGRADE" -ne 1 ) ]]
		then
		    CUR=`pwd`		
		    OSP_PARAM_STR="-slc -ssc -log ${LOG_FILE_NAME}"
		    cd $DIR/../osp
		    ./install.sh ${OSP_PARAM_STR} -prod "user_application"
              cd $CUR	    
		fi
	fi
	
    #install common libraries
    if [[ ( "$IS_UPGRADE" -eq 1 && $IS_UA_UPGRADED -eq 0 ) || ( "$IS_UPGRADE" -ne 1 ) ]]
    then
        strerr=`gettext install "Common libraries installation failed. Check logs for more details."`
        install_common_libs `pwd`/common.deps
        check_errs $? $strerr
        RET=$?
        check_return_value $RET
    else
        write_log "Skipping installation of common libraries for Reporting."
    fi

    if [[ ( "$IS_UPGRADE" -eq 1 && $IS_ACTIVEMQ_INSTALLED -eq 1 ) || ( "$IS_UPGRADE" -ne 1 ) ]]
    then
        install_common_libs `pwd`/activemq.deps "NA"
    fi
    newrptredirecthost=$(grep com.netiq.rpt.rpt-web.redirect.url ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | grep -iv "localhost:8180" | cut -d":" -f2 | cut -d"/" -f3)
    oldrptredirecthost=$(grep com.netiq.rpt.redirect.url ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | cut -d":" -f2 | cut -d"/" -f3)
    osphost=$(grep "com.netiq.idm.osp.url.host[[:blank:]]*=" ${IDM_TOMCAT_HOME}/conf/ism-configuration.properties | cut -d":" -f2 | cut -d"/" -f3)
    grep $osphost /etc/hosts | grep $newrptredirecthost &> /dev/null
    newrptospsamename=$?
    grep $osphost /etc/hosts | grep $oldrptredirecthost &> /dev/null
    oldrptospsamename=$?
    if [ "$newrptredirecthost" == "$osphost" ] || [ "$oldrptredirecthost" == "$osphost" ] || [ $newrptospsamename -eq 0 ] || [ $oldrptospsamename -eq 0 ]
    then
    	if [ $IS_UA_UPGRADED -eq 0 ]
	then
		export RPT_OSP_INSTALLED=y
	fi
    fi


    if [ $IS_UPGRADE -eq 1 ] && [ "$RPT_OSP_INSTALLED" == "y" ] && [ $IS_UA_UPGRADED -eq 0 ]
    then
        upgrade_pre_install
        RET=$?
        check_return_value $RET
    else
        write_log "Skipping installation of OSP for Reporting."
    fi

    if [ $IS_UPGRADE -ne 1 ]
    then
    	if [ ! -z "$DOCKER_CONTAINER" ] && [ "$DOCKER_CONTAINER" == "y" ]
	then
        	strerr=`gettext install "PostgreSQL installation failed: Check logs for more details."`
        	install_postgres
        	check_errs $? $strerr
        	RET=$?
        	check_return_value $RET
	fi
    fi
	
    ##RPM installation
    strerr=`gettext install "Reporting RPM installation failed: Check logs for more details."`
    installrpm `pwd`/packages reporting.list
    check_errs $? $strerr
    RET=$?
    check_return_value $RET
    installrpm "${IDM_INSTALL_HOME}common/packages/tomcat" ../common/packages/tomcat/deps.list

    if [ $IS_UPGRADE -ne 1 ]
    then
        add_config_option $CONFIGURE_FILE
    fi

    if [ -d ${RPT_CONFIG_HOME} ]
    then
        chown -R novlua:novlua  ${RPT_CONFIG_HOME}
    fi

    if [ $IS_UPGRADE -eq 1 ]
    then
        reporting_post_upgrade
        if [ -n "${SSO_SERVER_HOST}" ]
        then
	    validateIP "${SSO_SERVER_HOST}"
            RET=$?

            if [ $RET -eq 1 ]
            then
                rpm -e netiq-osp-4.7.0-0.noarch --nodeps
            fi
        fi
        #
        if [ -f /opt/rptcon_upgrade.properties ]
        then
          rm -rf /opt/rptcon_upgrade.properties
        fi

        if [ -f /opt/rpt_upgrade.properties ]
        then
          rm -rf /opt/rpt_upgrade.properties
        fi
	addauditcachefiledir
    fi
    mkdir -p ${UNINSTALL_FILE_DIR}/reporting &> /dev/null
    yes | cp -rpf ../common ${UNINSTALL_FILE_DIR}/ &> /dev/null
    yes | cp -rpf uninstall.sh ${UNINSTALL_FILE_DIR}/reporting/ &> /dev/null

    copyThirdPartyLicense
    removetruststoreentryfromsetenv
    ismPropertiesChangeUAandRPT
    RemoveAJPConnector
    revertoffcloudjre8
    updatetomcatversion_for_osp
}

main $*
