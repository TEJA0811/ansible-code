#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

export IDM_INSTALL_HOME=`pwd`/../

. ../common/conf/global_variables.sh
. ../common/conf/global_paths.sh
. ../common/scripts/prompts.sh
. ../common/scripts/configureInput.sh
. ../common/scripts/common_install_vars.sh
. ../common/scripts/commonlog.sh
. ../common/scripts/prompts.sh
. ../common/scripts/multi_select.sh
. ../common/scripts/config_utils.sh
. ../common/scripts/system_utils.sh
. ../common/scripts/install_common_libs.sh 	 
. ../common/scripts/install_check.sh
. ../common/scripts/common_install_error.sh
. ../common/scripts/locale.sh

EDIRVERSIONINST=
LOG_FILE_NAME=/var/opt/netiq/idm/log/idmconfigure.log

initLocale

## eDirectory version installed obtained from novell-NDSserv rpm

main()
{
    set_log_file "${LOG_FILE_NAME}"
    parse_install_params $*
    check_installed_components
    if [ ! -d /opt/netiq/idm/uninstall_data/IDVault ]
    then
    	str1=`gettext install "Identity Store not installed - exiting..."`
	write_and_log "$str1"
	exit 1
    fi
    config_mode 	 
    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf 	 
    process_prompts "ID Vault" $IS_IDVAULT_INSTALLED

	checkeDirExist
	userid=`id -u`
	if [ "$EDIRVERSIONINST" != "" -a ! -s "/etc/opt/novell/eDirectory/conf/.edir/instances.${userid}" ]
	then
	    config_mode
		write_and_log ""
                 source scripts/prompts.sh

        
		if [ "$ID_VAULT_TREENAME" = "IDENTITYMANAGER" ] || [ "$ID_VAULT_TREENAME" = "" ]
		then
#			ID_VAULT_TREENAME="$ID_VAULT_TREENAME-`date +'%y%m%d%H%M'`"
                        ID_VAULT_TREENAME="$ID_VAULT_TREENAME"
		fi


		setVariableValue "ID_VAULT_TREENAME" "${ID_VAULT_TREENAME}"

		if [ -f "${PASSCONF}" ]
		then
			source "${PASSCONF}"
		fi
                str1=`gettext install "Configuring Identity Store"`
		write_and_log "$str1"
		RC=0	
		if [ "$TREE_CONFIG" == "newtree" ]
		then
			/opt/novell/eDirectory/bin/ndsconfig new -T -S $ID_VAULT_SERVERNAME -t $ID_VAULT_TREENAME -n $ID_VAULT_SERVER_CONTEXT -a $ID_VAULT_ADMIN -D $ID_VAULT_VARDIR -c -d $ID_VAULT_DIB --configure-eba-now yes -B @"$ID_VAULT_NCP_PORT" -L $ID_VAULT_LDAP_PORT -l $ID_VAULT_LDAPS_PORT -o $ID_VAULT_HTTP_PORT -O $ID_VAULT_HTTPS_PORT -w "${ID_VAULT_PASSWORD}" --pki-default-rsa-keysize $ID_VAULT_RSA_KEYSIZE --pki-default-ec-curve $ID_VAULT_EC_CURVE --pki-default-cert-life $ID_VAULT_CA_LIFE --config-file $ID_VAULT_CONF >> $log_file 2>&1
			RC=$?
		elif [ "$TREE_CONFIG" == "existingtreeremote" ]
		then
			/opt/novell/eDirectory/bin/ndsconfig add -S $ID_VAULT_SERVERNAME -t $ID_VAULT_TREENAME -p ${ID_VAULT_EXISTING_SERVER}:${ID_VAULT_EXISTING_NCP_PORT} -n "${ID_VAULT_EXISTING_CONTEXTDN}" -a $ID_VAULT_ADMIN -D $ID_VAULT_VARDIR -c -d $ID_VAULT_DIB --configure-eba-now no -B @"$ID_VAULT_NCP_PORT" -L $ID_VAULT_LDAP_PORT -l $ID_VAULT_LDAPS_PORT -o $ID_VAULT_HTTP_PORT -O $ID_VAULT_HTTPS_PORT -w "${ID_VAULT_PASSWORD}" --config-file $ID_VAULT_CONF >> $log_file 2>&1
			RC=$?
		fi
if [ $RC -ne 0 ]
then
 check_conf $RC "Error while Configuring Identity Store"
 exit $RC
 fi
	fi
}

main $*
