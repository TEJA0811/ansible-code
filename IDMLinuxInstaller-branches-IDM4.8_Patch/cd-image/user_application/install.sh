#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../


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
. ../common/scripts/os_helper_utils.sh
. ../common/scripts/prompts.sh
. ../common/scripts/installupgrpm.sh
. ../common/scripts/cert_utils.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/ldap_utils.sh
. ../common/scripts/database_utils.sh
. ../common/scripts/components_version.sh
. ../osp/scripts/osp_configure.sh
. ../osp/scripts/pre_install.sh
. ../osp/scripts/merge_cust_loc.sh
. ../osp/osp_pre_upgrade.sh
. ../osp/osp_post_upgrade.sh
. ../sspr/sspr_pre_upgrade.sh
. ../sspr/sspr_post_upgrade.sh
. ../sspr/scripts/sspr_config.sh
. ../sspr/scripts/sspr_config_util.sh
. ../common/scripts/ism_cfg_util.sh
. ../common/scripts/audit.sh
. ../common/scripts/locale.sh

. ./pre_upgrade.sh
. ./post_upgrade.sh


. scripts/pre_install.sh
. scripts/ua_install.sh
. scripts/ua_upgrade.sh
. scripts/ua_configure.sh


CONFIGURE_FILE=user_application
CONFIGURE_FILE_DISPLAY="Identity Applications"
LOG_FILE_NAME=/var/opt/netiq/idm/log/idminstall.log
#IS_UPGRADE=1

initLocale

main()
{
    parse_install_params $*
    if [ $IS_WRAPPER_CFG_INST -eq 0 ]
    then
        cleanup_tmp
    fi
    init
	create_IP_cfg_file_conditionally
    foldername_space_check
    exitIfnotRunfromWrapper
    system_validate
    display_copyrights
    write_and_log ""

    IS_RPT_UPGRADED=0
    if [ $IS_UPGRADE -eq 1 ]
    then
		isRPTUpgraded
        IS_RPT_UPGRADED=$?
    fi

    is_activemq_installed
    if [ $IS_UPGRADE -eq 1 ]
    then
        #Install common dependencies
        if [ $IS_RPT_UPGRADED -eq 0 ]
        then
            install_common_libs `pwd`/java.deps
        fi
        LOG_FILE_NAME=/var/opt/netiq/idm/log/idmupgrade.log
        DB_LOG_OUT=/var/opt/netiq/idm/log/uadb.out
        IS_ADVANCED_MODE="true"
	rpm -qi netiq-tomcatconfig &> /dev/null
	if [ $? -eq 0 ]
	then
		INSTALLED_FOLDER_PATH=/opt/netiq/idm/apps
	else
        	INSTALLED_FOLDER_PATH=`grep -i 'TOMCAT_PARENT_DIR=' /etc/init.d/idmapps_tomcat_init | cut -d '=' -f2`
	fi
        EXISTING_SSPR_INSTALLED_PATH=`grep 'Dsspr' ${INSTALLED_FOLDER_PATH}/tomcat/bin/setenv.sh | grep -v [[:blank:]]# | grep -v ^# | awk -F "Dsspr" '{print $2}' | cut -d ' ' -f 1 | cut -d '=' -f 2 | cut -d '"' -f1 | xargs`
        #Check OSP installed
        IS_OSP_EXIST="false"
        if [ -f ${INSTALLED_FOLDER_PATH}/tomcat/webapps/osp.war ]
        then
          IS_OSP_EXIST="true"
        fi
  
        Replace80and443PortWithNULL $INSTALLED_FOLDER_PATH
        
        OSP_INSTALLED_LOCAL="false"
        if [ -f ${INSTALLED_FOLDER_PATH}/tomcat/webapps/osp.war ]
        then 
          OSP_INSTALLED_LOCAL="true"
        else
          OSP_INSTALLED_LOCAL="false"
        fi

        #
        if [ -f "${INSTALLED_FOLDER_PATH}/tomcat/webapps/sspr.war" ]
        then
           SSPR_INSTALLED_LOCAL="true" 
           SSPR_INSTALLED_FOLDER_PATH=`/usr/bin/dirname $EXISTING_SSPR_INSTALLED_PATH` 
	   SSPR_INSTALL_FOLDER=$SSPR_INSTALLED_FOLDER_PATH
        else 
           SSPR_INSTALLED_LOCAL="false"
           SSPR_INSTALLED_FOLDER_PATH=
        fi

        # 
        #init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf
        #process_prompts "Identity Applications" $OSP_INSTALL_FOLDER
        
        if [ "${SSPR_INSTALLED_LOCAL}" == "true" ]
        then
           SSPR_INSTALLED_FOLDER_PATH=${SSPR_INSTALL_FOLDER}
        fi
        #
	if [ -f /opt/uacon_upgrade.properties ]
	then
	  rm /opt/uacon_upgrade.properties
	  touch /opt/uacon_upgrade.properties
	else
	   touch /opt/uacon_upgrade.properties
        fi
        #readconfigpropertiesfordbconn
        sed -i 's#\\##g' /opt/uacon_upgrade.properties
        source /opt/uacon_upgrade.properties

        if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "postgres" ]
        then
            DB_TYPE="PostgreSQL"
	    if [ -z "$WFE_DB_CONNECTION_URL" ] || [ "$WFE_DB_CONNECTION_URL" == "" ]
	    then
	      WFE_DB_CONNECTION_URL="jdbc:postgresql://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}/${WFE_DATABASE_NAME}?compatible=true"
	    fi
        elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
        then
            DB_TYPE="Oracle"
	    if [ -z "$WFE_DB_CONNECTION_URL" ] || [ "$WFE_DB_CONNECTION_URL" == "" ]
	    then
	      WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${WFE_DATABASE_NAME}"
	    fi
        elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
        then
            DB_TYPE="SQL Server"
	    if [ -z "$WFE_DB_CONNECTION_URL" ] || [ "$WFE_DB_CONNECTION_URL" == "" ]
	    then
	      WFE_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${WFE_DATABASE_NAME}"
	    fi
        fi
	#Not doing db check with Patch
        #verify_db_connection ${UA_WFE_DATABASE_USER} ${UA_WFE_DATABASE_PWD} "${UA_DB_CONNECTION_URL}" "${DB_TYPE}" ${UA_WFE_DB_JDBC_DRIVER_JAR}
	UA_DB_CONN_RET=0
        #verify_db_connection ${UA_WFE_DATABASE_USER} ${UA_WFE_DATABASE_PWD} "${WFE_DB_CONNECTION_URL}" "${DB_TYPE}" ${UA_WFE_DB_JDBC_DRIVER_JAR}
	WFE_DB_CONN_RET=0
	DB_CONN_RET=0
	foundVersion=`rpm -qa --queryformat '%{version}' netiq-userapp`
	if (( $(awk 'BEGIN {print ("'$foundVersion'" >= "'$CURRENT_IDM_VERSION'")}') ))
	then
		# For 4.8 and above
		if [ $UA_DB_CONN_RET -eq 1 ] || [ $WFE_DB_CONN_RET -eq 1 ]
		then
			DB_CONN_RET=1
		fi
	else
		# Till 4.7.x
		if [ $UA_DB_CONN_RET -eq 1 ]
		then
			DB_CONN_RET=1
		fi
	fi

        if [ $DB_CONN_RET -eq 1 ]
        then
	       disp_str=`gettext install "Connection to database failed. Check database is running or parameters provided is valid. Run upgrade after correcting problem."`
		  write_and_log "$disp_str"
		  exit
        else
		  disp_str=`gettext install "Database connection successful."`
		  #write_and_log "$disp_str"
        fi
        userapp_pre_upgrade
    else
         #Setup designer..
        ${IDM_INSTALL_HOME}/designer/install.sh ${*}
        RET=$?    
        check_return_value $RET
    fi

	#install OSP
	if [ $IS_WRAPPER_CFG_INST -eq 0 ]
	then
        if [[ ( "$IS_UPGRADE" -eq 1 && $IS_RPT_UPGRADED -eq 0 ) || ( "$IS_UPGRADE" -ne 1 ) ]]
        then
            CUR=`pwd`		
            OSP_PARAM_STR="-s -slc -ssc -log ${LOG_FILE_NAME}"
            cd $DIR/../osp
	    if [ -z $ENABLE_STANDALONE ]
	    then
            	./install.sh ${OSP_PARAM_STR} -prod "user_application"
	    fi
        fi
        
        #If SSPR is installed on this setup, then only SSPR will get upgraded.
	rpm -qa netiq-sspr &> /dev/null
        if [ $? -eq 0 ] || [ ! -z $SSPR_INSTALLED_FOLDER_PATH ]
        then  
            cd $DIR/../sspr	
            ./install.sh ${OSP_PARAM_STR} -prod "user_application"	
        fi
        cd $CUR	            
	fi
	
    #install common libraries
    strerr=`gettext install "Common libraries installation failed. Check logs for more details."`
    if [ $IS_UPGRADE -eq 1 ]
    then
        if [ $IS_RPT_UPGRADED -eq 1 ]
        then
            install_common_libs `pwd`/upgrade.deps
            check_errs $? $strerr
            RET=$?
            check_return_value $RET
        else
            install_common_libs `pwd`/common.deps
            check_errs $? $strerr
            RET=$?
            check_return_value $RET
        fi
    else
        install_common_libs `pwd`/common.deps
        check_errs $? $strerr
        RET=$?
        check_return_value $RET    
    fi

    if [[ ( "$IS_UPGRADE" -eq 1 && $IS_ACTIVEMQ_INSTALLED -eq 1 ) || ( "$IS_UPGRADE" -ne 1 ) ]]
    then
        install_common_libs `pwd`/activemq.deps "NA"
    fi

    if [ $IS_UPGRADE -eq 1 ]
    then
        strerr=`gettext install "Read Installed configuration"`
        readconfigproperties
 
        #OSP INSTALL
        if [ $IS_RPT_UPGRADED -eq 0 ]
        then
            upgrade_pre_install
            RET=$?
            check_return_value $RET
        else
            write_log "Skipping installation of OSP for Identity Applications"
        fi
     
        #SSPR INSTALL
        # If SSPR is installed on this setup, then only SSPR will get upgraded.
        # otherwise ask a question about installing it or not
        rpm -qa netiq-sspr &> /dev/null
	if [ $? -eq 0 ] || [ ! -z $SSPR_INSTALLED_FOLDER_PATH ]
        then
            upgrade_sspr_install
            RET=$?
            check_return_value $RET
        else
            #prompt "UA_UPG_INSTALL_SSPR" - "y/n"
            if [ "$UA_UPG_INSTALL_SSPR" == "y" ]
            then
                CUR=`pwd`		
		        SSPR_PARAM_STR="-s -slc -wci -ssc -log ${LOG_FILE_NAME}"
                cd $DIR/../sspr	
                ./install.sh ${SSPR_PARAM_STR} -prod "user_application"
                #source $DIR/../sspr/scripts/prompts.sh
                str1=`gettext install "Initializing SSPR configurations. "`
                write_and_log "$str1"
                if [ $UNATTENDED_INSTALL -eq 1 ]
                then
                    SSPR_PARAM_STR="-s -slc -wci -ssc -log ${LOG_FILE_NAME} -sup"
                else
                    SSPR_PARAM_STR="-slc -wci -ssc -log ${LOG_FILE_NAME} -sup"
                fi
                ./configure.sh ${SSPR_PARAM_STR} -prod "user_application"
                cd $CUR
            fi	
        fi
    fi

    if [ $IS_UPGRADE -ne 1 ]
    then
    	if [ ! -z "$DOCKER_CONTAINER" ] && [ "$DOCKER_CONTAINER" == "y" ]
	then
        	install_postgres	   
        	RET=$?
        	check_return_value $RET
	fi
    fi

    #strerr=`gettext install "Identity Applications Utils RPM failed"`
    #install_ua_utils
    #check_errs $? $strerr
    #RET=$?
    #check_return_value $RET
  
    #sterr=`gettext install "Identity Applications WAR RPM failed"`
    #install_ua_wars 
    #check_errs $? $strerr
    #RET=$?
    #check_return_value $RET
    installrpm "${IDM_INSTALL_HOME}/user_application/packages/ua" ua.list
    installrpm "${IDM_INSTALL_HOME}common/packages/tomcat" ../common/packages/tomcat/deps.list
    installrpm "${IDM_INSTALL_HOME}user_application/packages/ua" wf.list

    if [ -z "$FR_STANDALONE" ]
    then
    	formsinstall
    fi

    #if [ $IS_OSP_INSTALLED -eq 1 && $IS_SSPR_INSTALLED -eq 1]
    #then
#        echo $'\n' installing User Application
#        installrpm `pwd`/packages ua.list
    #fi
   # cp `pwd`/packages/idm-datasource-factory-uber.jar ${IDM_TOMCAT_HOME}/lib/idm-datasource-factory-uber.jar

    if [ $IS_UPGRADE -ne 1 ]
    then
      add_config_option $CONFIGURE_FILE
    fi
 
    if [ $IS_UPGRADE -eq 1 ]
    then
       #post upgrade
       userapp_post_upgrade
	   PostUpgrade
        
      #Start tomcat - commented out for Bug 1076158
      #systemctl restart netiq-tomcat
      update_osphost_ism
      update_ssprhost_ism
      if [ ! -z "$USE_EXISTING_CERT_WITH_SAN" ] && [ "$USE_EXISTING_CERT_WITH_SAN" == "n" ]
      then
        if [ ! -z "$UA_COMM_TOMCAT_KEYSTORE_FILE" ]
	then
	  present_keystore_path=`grep -ir "com.netiq.idm.osp.ssl-keystore.file =" /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | grep -v "#" | awk '{print $3}' | sed 's/^[ ]*//'`
	  cp $UA_COMM_TOMCAT_KEYSTORE_FILE $present_keystore_path
	fi
        import_vault_certificates
	keystorePassToCustom_UA
      fi
      #Need to 
      if [ -f /opt/uacon_upgrade.properties ]
      then 
        rm -rf /opt/uacon_upgrade.properties
      fi
      
      if [ -f /opt/ua_upgrade.properties ]
      then
         rm -rf /opt/ua_upgrade.properties
      fi
      configure_nginx
      if [ -d /opt/netiq/idm/apps/tomcat/temp/permindex ]
      then
        rm -rf /opt/netiq/idm/apps/tomcat/temp/permindex
      fi
      addauditcachefiledir
      systemctl restart netiq-nginx &> /dev/null
      systemctl enable netiq-nginx &> /dev/null
    fi

    mkdir -p ${UNINSTALL_FILE_DIR}/user_application &> /dev/null
    yes | cp -rpf ../common ${UNINSTALL_FILE_DIR}/ &> /dev/null
    yes | cp -rpf uninstall.sh ${UNINSTALL_FILE_DIR}/user_application/ &> /dev/null
    yes | cp -rpf ua.list forms.list wf.list ${UNINSTALL_FILE_DIR}/user_application/ &> /dev/null
    if [ -d "$CONFIGURE_FILE_DIR" ]
    then
      touch ${NOT_CONFIGURED_FOR_CLOUD} &> /dev/null
    fi
    copyThirdPartyLicense
    removetruststoreentryfromsetenv
    ismPropertiesChangeUAandRPT
    RemoveAJPConnector
    grantToauth
    jre8zipextract
    configupdatejre8unlink
    fixforsecretstore
    updatetomcatversion_for_osp
}

main $*
