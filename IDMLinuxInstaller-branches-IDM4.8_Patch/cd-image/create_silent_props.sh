#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

rm -rf /tmp/idm_install


function box_out()
{
  local s=("$@") b w
  for l in "${s[@]}"; do
    ((w<${#l})) && { b="$l"; w="${#l}"; }
  done
  tput setaf 3
  echo "┌─${b//?/─}─┐
│ ${b//?/ } │"
  for l in "${s[@]}"; do
    printf '│ %s%*s%s │\n' "$(tput setaf 3)" "-$w" "$l" "$(tput setaf 3)"
  done
  echo "│ ${b//?/ } │
└─${b//?/─}─┘"
  tput sgr 0
}

function display_info()
{
  local info="${1}"

  tput setaf 3
  echo $info
  tput sgr0
}

spinner()
{
    local PROC="$1"
    local processingStr=`gettext install "Processing"`
    local str="${2:-$processingStr ...}"
    local delay="0.3"
    tput civis  # hide cursor
    trap 'tput cnorm' EXIT
    while [ -d /proc/$PROC ]; do
        printf '\033[s\033[u / %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u — %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u \ %s\033[u' "$str"; sleep "$delay"
        printf '\033[s\033[u | %s\033[u' "$str"; sleep "$delay"
    done
    printf '\033[s\033[u%*s\033[u\033[0m' $((${#str}+6)) " "  # return to normal
    tput cnorm  # restore cursor
    return 0
}

get_14_digit_random_number()
{
    if [ $# -eq 1 ]
    then
      maxnumber=$1
    else
      maxnumber=13
    fi
    local number=$RANDOM;
    let "number %= 9";
    let "number = number + 1";
    local range=10;
    for i in `seq 1 $maxnumber`; do
      r=$RANDOM;
      let "r %= $range";
      number="$number""$r";
    done;
    echo $number
}

function vmanddbpwdlower()
{
	if [ $# -eq 1 ]
	then
        	length=$1
	else
	        length=8
	fi
	lower=({a..k} {m..n} {p..z})
	CharArray=(${lower[*]})
	ArrayLength=${#CharArray[*]}
	password=""
	for i in `seq 1 $length`
	do
	        index=$(($RANDOM%$ArrayLength))
	        char=${CharArray[$index]}
	        password=${password}${char}
	done
	echo ${password}
}


function vmanddbpwdupper()
{
	if [ $# -eq 1 ]
	then
        	length=$1
	else
	        length=8
	fi
	upper=({A..N} {P..Z})
	CharArray=(${upper[*]})
	ArrayLength=${#CharArray[*]}
	password=""
	for i in `seq 1 $length`
	do
	        index=$(($RANDOM%$ArrayLength))
	        char=${CharArray[$index]}
	        password=${password}${char}
	done
	echo ${password}
}

valid_ip()
{
    local  ip=$1
    isValidIP=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        isValidIP=$?
    fi
    return $isValidIP
}

create_IP_cfg_file_conditionally()
{
	IDM_TEMP=/tmp/idm_install
	if [ ! -d "${IDM_TEMP}" ]
	then
		mkdir "${IDM_TEMP}" >> /dev/null
	fi
	IP_SAVE_FILE="${IDM_TEMP}/IP.cfg"
	SINGLE_IP_SAVE_FILE="${IDM_TEMP}/SINGLEIP.cfg"
	if [ ! -f ${IP_SAVE_FILE} ]
	then
		ip_address_list=`/sbin/ip -f inet addr list | grep -E '^[[:space:]]*inet' | sed -n '/127\.0\.0\./!p' | awk '{print $2}' | awk -F '/' '{print $1}'`
		NUMBER_OF_IP_CONFIGURED=`echo $ip_address_list | awk -F' ' '{print NF; exit}'`
		if [ ${NUMBER_OF_IP_CONFIGURED} -gt "1" ]
		then
			# More than one ip has been configured
			CHOSEN_IP=`echo $ip_address_list | awk '{print $1}'`
			echo "IP_ADDR=${CHOSEN_IP}" > ${IP_SAVE_FILE}
		fi
		if [ ${NUMBER_OF_IP_CONFIGURED} -eq "1" ]
		then
			# Only one ip has been configured
			CHOSEN_IP=`echo $ip_address_list`
			echo "IP_ADDR=${CHOSEN_IP}" > ${SINGLE_IP_SAVE_FILE}
			echo "IP_ADDR=${CHOSEN_IP}" > ${IP_SAVE_FILE}
		fi
	fi
}
create_IP_cfg_file_conditionally

export IDM_INSTALL_HOME=`pwd`/

. gettext.sh

. common/conf/global_variables.sh
. common/conf/global_paths.sh
. common/scripts/common_install_vars.sh
. common/scripts/commonlog.sh
. common/scripts/multi_select.sh
. common/scripts/configureInput.sh
. common/scripts/prompts.sh
. common/scripts/system_utils.sh
. common/scripts/config_utils.sh
. common/scripts/installupgrpm.sh
. common/scripts/install_common_libs.sh
. common/scripts/install_check.sh
. common/scripts/locale.sh
. common/scripts/kube_create_yaml.sh
. common/scripts/kube_generate_values_yaml.sh
IS_UPGRADE=0
PRODUCTS=("IDM" "IDMRL" "IDMFO" "iManager" "reporting" "idconsole" "user_application" )
PRODUCTS_DISP_NAME=("Identity Manager Engine" "Identity Manager Remote Loader Service" "Identity Manager Fanout Agent" "iManager Web Administration"   "Identity Reporting" "Identity Console" "Identity Applications" )
RLonlysetup

export LOG_FILE_NAME=/var/opt/netiq/idm/log/idmprompts.log
SKIP_LDAP_SERVER_VALIDATION="true"
SKIP_BTRFS_CHECK=1

PARAM_STR=
CFG_MODE=
CREATE_SILENT_FILE=true

initLocale

configure_product()
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
    if [ "$PROD_NAME" = "user_application" ]
    then
        source osp/scripts/prompts.sh 
        source sspr/scripts/prompts.sh 
    fi



    if [ "${COMPONENT}" != "" ]
    then
       source ${PROD_NAME}/scripts/prompts.sh 
    else
       source ${PROD_NAME}/scripts/prompts.sh 
    fi


}

update_config_list()
{
    local COUNT=${#PRODUCTS[@]}
    for (( i = 0 ; i < $COUNT ; i++ ))
    do
        MENU_OPTIONS+=("${PRODUCTS[i]}")
        MENU_OPTIONS_DISPLAY+=("${PRODUCTS_DISP_NAME[i]}")
    done
}

typical_or_advanced()
{
	OPT=true
    typicalSTRING=`gettext install "Typical Configuration"`
    customSTRING=`gettext install "Custom Configuration"`
    while ${OPT}
    do
        MENU_OPTIONS=("typical", "advanced")
        MENU_OPTIONS_DISPLAY=("${typicalSTRING}" "${customSTRING}")
        MESSAGE=`gettext install "Select the configuration mode. Typical configuration is for new installation and demo setup. Custom configuration is for advanced users."`
        get_user_input 1
        CFG_MODE=${SELECTION[0]}
        if [ "$CFG_MODE" == "advanced"  ] 
        then
            IS_ADVANCED_MODE="true"
        else 
            IS_ADVANCED_MODE="false"
        fi
        local COUNT=${#SELECTION[@]}
        if ((${COUNT} != 1 ))
        then
            str1=`gettext install "Invalid configuration mode. Choose only one option.."`
            write_and_log "${str1}"
            SELECTION=()
            SELECTION_DISPLAY=()
            MENU_USER_CHOICES=()
        else
            OPT=false
        fi
    done
    
    MENU_OPTIONS=()
    MENU_OPTIONS_DISPLAY=()
    SELECTION=()
    SELECTION_DISPLAY=()
    MENU_USER_CHOICES=()
}


prompt_for_azure_pg()
{ 

        local components=("$@")
        local apps_selected=false
        local rpt_selected=false

        for i in ${components[@]};
        do
          if [ "$i" == "user_application" ]
          then
            apps_selected=true
          elif [ "$i" == "reporting" ]
          then
            rpt_selected=true
          fi
        done 

        local azure_pg_info=""
        if [ "$apps_selected" == "true" ] && [ "$rpt_selected" == "true" ]
        then
          azure_pg_info=`gettext install "Terraform configuration provides option to create a new Azure PostgreSQL Server instance for Identity Applications and Identity Reporting.
                                            Select 'y' if you want Terraform to create a new Azure PostgreSQL Server instance.
                                             If you want to use an existing Database Server, select 'n'."`
        elif [ "$apps_selected" == "true" ]
        then
          azure_pg_info=`gettext install "Terraform configuration provides option to create a new Azure PostgreSQL Server instance for Identity Applications.
                                            Select 'y' if you want Terraform to create a new Azure PostgreSQL Server instance.
                                             If you want to use an existing Database Server, select 'n'."`

        else
          azure_pg_info=`gettext install "Terraform configuration provides option to create a new Azure PostgreSQL Server instance for Identity Reporting.
                                            Select 'y' if you want Terraform to create a new Azure PostgreSQL Server instance.
                                             If you want to use an existing Database Server, select 'n'."`
        fi

        display_info "${azure_pg_info}"

        prompt AZURE_POSTGRESQL_REQUIRED
        if [ ! -z "$AZURE_POSTGRESQL_REQUIRED" ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
        then
          prompt AZURE_POSTGRESQL_SERVERNAME_PREFIX
          fourteendigitnumber=$(get_14_digit_random_number)
          AZURE_POSTGRESQL_SERVER_NAME=`echo ${AZURE_POSTGRESQL_SERVERNAME_PREFIX}-${fourteendigitnumber}.postgres.database.azure.com`
          export AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM=`echo ${AZURE_POSTGRESQL_SERVERNAME_PREFIX}-${fourteendigitnumber}`
          save_prompt "AZURE_POSTGRESQL_SERVER_NAME"
          echo_sameline "${txtylw}"
          pgservername=`gettext install "Your Azure PostgreSQL Server name is"`
          write_and_log "    ${pgservername} ${AZURE_POSTGRESQL_SERVER_NAME}"
          pgnamewarn=`gettext install "If the server name creation fails, try with a different name. For more details, see the Architecture document."`
          echo ""
          write_and_log "    ${pgnamewarn}"
          echo_sameline "${txtrst}"
          echo ""
          AZURE_POSTGRESQL_ADMIN_USER="postgres"
          save_prompt "AZURE_POSTGRESQL_ADMIN_USER"
          if [ ! -z $azurevmanddbpwd ]
          then
            AZURE_POSTGRESQL_ADMIN_USER_PWD=${azurevmanddbpwd}
            save_prompt "AZURE_POSTGRESQL_ADMIN_USER_PWD"
          fi
          prompt_pwd "AZURE_POSTGRESQL_ADMIN_USER_PWD" confirm
          RPT_DATABASE_HOST="$AZURE_POSTGRESQL_SERVER_NAME"
          save_prompt "RPT_DATABASE_HOST"
          RPT_DATABASE_PORT=5432
          save_prompt "RPT_DATABASE_PORT"
          RPT_DATABASE_NAME="idmrptdb"
          save_prompt "RPT_DATABASE_NAME"
          RPT_DATABASE_JDBC_DRIVER_JAR="/opt/netiq/idm/apps/tomcat/lib/postgresql-42.4.1.jar"
          save_prompt "RPT_DATABASE_JDBC_DRIVER_JAR"
          RPT_DATABASE_USER="$AZURE_POSTGRESQL_ADMIN_USER"
          save_prompt "RPT_DATABASE_USER"
          RPT_DATABASE_SHARE_PASSWORD="$AZURE_POSTGRESQL_ADMIN_USER_PWD"
          save_prompt "RPT_DATABASE_SHARE_PASSWORD"
          RPT_DATABASE_PASSWORD="$AZURE_POSTGRESQL_ADMIN_USER_PWD"
          save_prompt "RPT_DATABASE_PASSWORD"
          RPT_DATABASE_PLATFORM_OPTION="postgres"
          save_prompt "RPT_DATABASE_PLATFORM_OPTION"
          INSTALL_PG_DB_FOR_REPORTING="n"
          save_prompt "INSTALL_PG_DB_FOR_REPORTING"
          UA_WFE_DB_HOST="$AZURE_POSTGRESQL_SERVER_NAME"
          save_prompt "UA_WFE_DB_HOST"
          UA_WFE_DB_PLATFORM_OPTION="postgres"
          save_prompt "UA_WFE_DB_PLATFORM_OPTION"
          UA_WFE_DB_PORT=5432
          save_prompt "UA_WFE_DB_PORT"
          UA_WFE_DB_JDBC_DRIVER_JAR="/opt/netiq/idm/apps/tomcat/lib/postgresql-42.4.1.jar"
          save_prompt "UA_WFE_DB_JDBC_DRIVER_JAR"
          INSTALL_PG_DB="n"
          save_prompt "INSTALL_PG_DB"
          UA_WFE_DATABASE_ADMIN_PWD="$AZURE_POSTGRESQL_ADMIN_USER_PWD"
          save_prompt "UA_WFE_DATABASE_ADMIN_PWD"
          UA_DATABASE_NAME="idmuserappdb"
          save_prompt "UA_DATABASE_NAME"
          WFE_DATABASE_NAME="igaworkflowdb"
          save_prompt "WFE_DATABASE_NAME"
		  UA_WFE_DATABASE_USER="idmadmin"
		  save_prompt "UA_WFE_DATABASE_USER"
		  UA_WFE_DATABASE_PWD="pass1234WORD"
	      save_prompt "UA_WFE_DATABASE_PWD"
        fi
}

mask_for_all_dbs_kube()
{
	if [ ! -z ${KUBERNETES_ORCHESTRATION} ] && [ "${KUBERNETES_ORCHESTRATION}" == "y" ]
	then
		# For PG, MSSQL and Oracle - Masking the following prompts

		RPT_DATABASE_CREATE_OPTION="now"
		save_prompt "RPT_DATABASE_CREATE_OPTION"
		UA_WFE_DB_CREATE_OPTION="now"
		save_prompt "UA_WFE_DB_CREATE_OPTION"
		RPT_DATABASE_NEW_OR_EXIST="new"
		save_prompt "RPT_DATABASE_NEW_OR_EXIST"
		UA_DB_NEW_OR_EXIST="new"
		save_prompt "UA_DB_NEW_OR_EXIST"
		WFE_DB_NEW_OR_EXIST="new"
		save_prompt "WFE_DB_NEW_OR_EXIST"
        UA_WFE_DB_JDBC_DRIVER_JAR="/opt/netiq/idm/apps/tomcat/lib/postgresql-42.4.1.jar"
        save_prompt "UA_WFE_DB_JDBC_DRIVER_JAR"
        RPT_DATABASE_JDBC_DRIVER_JAR="/opt/netiq/idm/apps/tomcat/lib/postgresql-42.4.1.jar"
        save_prompt "RPT_DATABASE_JDBC_DRIVER_JAR"
        UA_WFE_DATABASE_ADMIN_PWD="changeit"
        save_prompt "UA_WFE_DATABASE_ADMIN_PWD"

		# For PG, MSSQL and Oracle - Masking the above prompts
	fi
}

prompt_for_azure_docker_host_vm()
{
    local azure_docker_host_vm_info=`gettext install "
        Terraform will create a virtual machine that will act as a Docker host for deploying Identity Manager Engine."`
    display_info "${azure_docker_host_vm_info}"
    
    echo ""
    prompt AZURE_DOCKER_VM_HOST_NAME
    ID_VAULT_HOST=$AZURE_DOCKER_VM_HOST_NAME.internal.cloudapp.net
    save_prompt "ID_VAULT_HOST"
    if [ ! -z $azurevmanddbpwd ]
    then
        AZURE_DOCKER_VM_HOST_PWD=${azurevmanddbpwd}
        save_prompt "AZURE_DOCKER_VM_HOST_PWD"
    fi
    prompt_pwd AZURE_DOCKER_VM_HOST_PWD confirm
    prompt AZURE_DOCKER_VM_ENGINE_DATADISK_SIZE
}

configure_interactive()
{      
    # Get the user configuration mode...
#    config_mode

#    install_common_libs `pwd`/base.deps

#    install_rpm "JRE" "netiq-jre-*.rpm" "${IDM_INSTALL_HOME}common/packages/java" "${log_file}" 
    echo ""
    welcome_str=`gettext install "This script will create configuration files required for installation/configuration of Identity Manager components."`
    firstsetpwd=$(vmanddbpwdupper 5)
    secondsetpwd=$(vmanddbpwdlower 5)
    firstthreedigitnumber=$(get_14_digit_random_number 2)
    secondthreedigitnumber=$(get_14_digit_random_number 2)
    export azurevmanddbpwd=$(echo ${firstsetpwd}${firstthreedigitnumber}${secondsetpwd}${secondthreedigitnumber})

    while [ 1 ]
	do
    if ls "${IDM_INSTALL_HOME}IDM/packages/driver" 1> /dev/null 2>&1
    then
        box_out "$welcome_str"
        echo ""
        check_and_install_jre
        prompt "DOCKER_CONTAINER" - "y/n"
    else
        export DOCKER_CONTAINER="y" 
        save_prompt "DOCKER_CONTAINER"
        exit_instruction_str=`gettext install "To exit anytime, press Ctrl+P followed by Ctrl+Q"`
        box_out "$welcome_str" "" "$exit_instruction_str"
        echo ""
    fi
    prompt "AZURE_CLOUD" - "y/n"
    DockerContainerSetup
    if [ ! -z "$AZURE_CLOUD" ] && [ "$AZURE_CLOUD" == "y" ]
    then
        if [ ! -f /opt/venv/bin/az ] || [ ! -f /usr/bin/docker ]
        then
            exit_if_az_or_docker_not_found=`gettext install "Azure CLI and Docker should be available in the machine from where you run.  You can try docker container using the image idm_conf_generator.  Exiting..."`
            display_info "$exit_if_az_or_docker_not_found"
            echo ""
            exit 1
        fi
    fi
    ask_file_name
	DIRPATH=$(dirname $S_FILE_NAME)
	if [[ ! -d "$DIRPATH" ]]; 
	then
	  str1=`gettext install "Enter a valid path"`
	  echo_sameline "${txtred}"
	  write_and_log " $str1"
	  echo_sameline "${txtrst}"
	else
	  break
    fi
	done
	# ask if it is an upgrade
	if [ "$DOCKER_CONTAINER" != "y" ]
	then
		echo ""
		echo "For Patch release; this script is exclusively for creating silent properties file with cloud containers only "
		echo ""
		exit 1
	fi
    if [ "$AZURE_CLOUD" == "y" ]
	then
        
        terraform_info=`gettext install "
        Micro Focus provides Terraform configuration files to set up the cloud infrastructure required for Identity Manager deployment."`
        display_info "${terraform_info}"
        echo ""
        export TERRAFORM_GENERATE="y"
        save_prompt "TERRAFORM_GENERATE"

        export KUBERNETES_ORCHESTRATION="y"

        if [ ! -z "$TERRAFORM_GENERATE" ] && [ "$TERRAFORM_GENERATE" == "y" ]
        then
          
          prompt KUBERNETES_NAMESPACE

          if [ -z $fourteendigitnumber ]
          then
            fourteendigitnumber=$(get_14_digit_random_number)
          fi
          AZURE_KEYVAULT=`echo idmkv${fourteendigitnumber}`
          save_prompt "AZURE_KEYVAULT"
          save_prompt "KUBERNETES_ORCHESTRATION"

        fi
    fi
	if [ "$DOCKER_CONTAINER" == "y" ]
	then
	    #echo ""
		UPGRADE_IDM=n
		ENABLE_STANDALONE=true
		EXCLUSIVE_SSPR=true
		EXCLUSIVE_SSO=true
	else
		prompt_check_upgrade
	fi
	save_prompt "UPGRADE_IDM"
	if [ -z "$EDIRAPI_PROMPT_NEEDED" ]
	then
	  EDIRAPI_PROMPT_NEEDED=n
	  save_prompt "EDIRAPI_PROMPT_NEEDED"
	fi
	if [ "$UPGRADE_IDM" != "y" ]
	then
		VAL="false"
		prompt_stand_advan
		if [ "$DOCKER_CONTAINER" == "n" ]
		then
		typical_or_advanced
		else
			IS_ADVANCED_MODE="true"
		fi
#	IS_ADVANCED_MODE="false"
	fi
	update_config_list

    if [ "$VAL" == "false" ]
    then
        unset 'MENU_OPTIONS[${#MENU_OPTIONS[@]}-1]'
        unset 'MENU_OPTIONS_DISPLAY[${#MENU_OPTIONS_DISPLAY[@]}-1]'
        IS_ADVANCED_EDITION="false"
    elif [ "$VAL" == "true" ]
	then
        IS_ADVANCED_EDITION="true"
    fi

    [ "$VAL" != "" ] && save_prompt "IS_ADVANCED_EDITION"

    local COUNT=${#MENU_OPTIONS[@]}
    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        PARAM_STR="${PARAM_STR} -sup" 
    fi    
    
    if [ ${COUNT} -eq 0 ]
    then
        str1=`gettext install "No Identity Manager components available for configuration... exiting."`
        write_and_log "${str1}"
    fi
    
    # In case there are multiple products, then
    # ask for use input for the products to configure  
    COUNT=${#MENU_OPTIONS[@]}
    if [ $COUNT -gt 0 ]
    then
        MESSAGE=`gettext install "Choose from the list of available components: "`
		OPT=true
		if [ $IS_UPGRADE -eq 1 ]
		then
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
			get_user_input
		fi
		SELECTIONSILENT=("${SELECTION[@]}")
	    COUNTSILENT=${#SELECTIONSILENT[@]}

        echo ""

        if [ ! -z $TERRAFORM_GENERATE ] && [ "$TERRAFORM_GENERATE" == "y" ]
        then


          # If Identity Applications and Reporting are selected, prompt for Azure PostgreSQL deployemnt options
          local comps_using_pg_list=()
          for (( k = 0 ; k < $COUNTSILENT ; k++ )) 
          {
              case "${SELECTIONSILENT[k]}" in
              "user_application" | "reporting")
                  comps_using_pg_list+=" ${SELECTIONSILENT[k]}"
                  ;;
              esac
          }
          # If the array is not empty, this means either Identity Applications or Reporting or both have been selected.
          if ((${#comps_using_pg_list[@]})); then
              prompt_for_azure_pg "${comps_using_pg_list[@]}"    
          fi


        fi
	mask_for_all_dbs_kube

        
        if [ "${KUBERNETES_ORCHESTRATION}" == "y" ]
        then
          for (( k = 0 ; k < $COUNTSILENT ; k++ )) 
          {
              case "${SELECTIONSILENT[k]}" in
              "user_application" | "reporting" | "idconsole")
                  prompt IDM_ACCESS_VIA_SINGLE_DOMAIN
                  prompt_file_required_during_silentfile IDM_ACCESS_SINGLE_DOMAIN_CRT_FILE
                  prompt_file_required_during_silentfile IDM_ACCESS_SINGLE_DOMAIN_KEY_FILE
                  break
                  ;;
              esac
          }
        fi

        common_pwd

        if [ "${KUBERNETES_ORCHESTRATION}" == "y" ]  
        then      
            COMMON_KEYSTORE_PWD="changeit"
            save_prompt "COMMON_KEYSTORE_PWD"
        fi

        if [ "${KUBERNETES_ORCHESTRATION}" == "y" ]
        then
          for (( k = 0 ; k < $COUNTSILENT ; k++ )) 
          {
            case "${SELECTIONSILENT[k]}" in
            "IDM")
		str1=`gettext install "NetIQ recommends you to have a maximum of 3 instances for Identity Manager Engine for optimal performance."`
		str2=`gettext install "More the replicas we have for a partition, the traffic between the servers may increase non-linearly."`
		str3=`gettext install "Though you can choose higher number for configuration when planned appropriately."`
                echo_sameline "${txtylw}"
          	write_and_log "    ${str1}"
          	write_and_log "    ${str2}"
          	write_and_log "    ${str3}"
                echo_sameline "${txtrst}"
                prompt ENGINE_REPLICA_COUNT
                ID_VAULT_HOST=idvault.internal.cloudapp.net
                save_prompt "ID_VAULT_HOST"
                ID_VAULT_SERVERNAME="IDVAULTSERVER"
                save_prompt "ID_VAULT_SERVERNAME"
                ID_VAULT_NCP_PORT=524
                save_prompt "ID_VAULT_NCP_PORT"
                ID_VAULT_LDAP_PORT=389
                save_prompt "ID_VAULT_LDAP_PORT"
                ID_VAULT_LDAPS_PORT=636
                save_prompt "ID_VAULT_LDAPS_PORT"
                ID_VAULT_HTTP_PORT=8028
                save_prompt "ID_VAULT_HTTP_PORT"
                ID_VAULT_HTTPS_PORT=8030
                save_prompt "ID_VAULT_HTTPS_PORT"
                ;;
            "user_application")
		prompt_validnumber UA_REPLICA_COUNT
                prompt_validnumber OSP_REPLICA_COUNT
                UA_CREATE_DRIVERS="y"
                save_prompt "UA_CREATE_DRIVERS"
                UA_DRIVER_NAME="User Application Driver"
                save_prompt "UA_DRIVER_NAME"
                ;;
            "reporting")
                RPT_SMTP_CONFIGURE="n"
                save_prompt "RPT_SMTP_CONFIGURE"
                RPT_SMTP_SERVER=""
                save_prompt "RPT_SMTP_SERVER"
                RPT_SMTP_SERVER_PORT=""
                save_prompt "RPT_SMTP_SERVER_PORT"
                RPT_DEFAULT_EMAIL_ADDRESS="admin@mycompany.com"
                save_prompt "RPT_DEFAULT_EMAIL_ADDRESS"
                RPT_CREATE_DRIVERS="y"
                save_prompt "RPT_CREATE_DRIVERS"
                ;;
            esac
          }
	fi

        # Setting the host and port according to single domain FQDN
        if [ ! -z "$IDM_ACCESS_VIA_SINGLE_DOMAIN" ]
        then
            for (( k = 0 ; k < $COUNTSILENT ; k++ ))
            do
                if [ "${SELECTIONSILENT[k]}" = "user_application" ]
                then
		       prompt_validnumber UA_REPLICA_COUNT
                    prompt_validnumber OSP_REPLICA_COUNT
		    prompt "ENABLE_CUSTOM_CONTAINER_CREATION"
		    if [ "$ENABLE_CUSTOM_CONTAINER_CREATION" == "n" ]
		    then
		    	ROOT_CONTAINER="o=data"
			save_prompt "ROOT_CONTAINER"
			GROUP_ROOT_CONTAINER="o=data"
			save_prompt "GROUP_ROOT_CONTAINER"
			USER_CONTAINER="o=data"
			save_prompt "USER_CONTAINER"
			ADMIN_CONTAINER="o=data"
			save_prompt "ADMIN_CONTAINER"
		    fi
                    if [ -z $SSO_SERVER_HOST ]
                    then
                        SSO_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                        save_prompt "SSO_SERVER_HOST"
                        SSO_SERVER_SSL_PORT=443
                        save_prompt "SSO_SERVER_SSL_PORT"
                    fi
                    UA_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "UA_SERVER_HOST"
                    FR_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "FR_SERVER_HOST"
                    UA_SERVER_SSL_PORT=443
                    save_prompt "UA_SERVER_SSL_PORT"
                    ACTIVEMQ_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "ACTIVEMQ_SERVER_HOST"
                    FOR_SSPR_CONTAINER="y"
                    save_prompt "FOR_SSPR_CONTAINER"
                    SSPR_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "SSPR_SERVER_HOST"
                    ACTIVEMQ_SERVER_TCP_PORT=61716
                    save_prompt "ACTIVEMQ_SERVER_TCP_PORT"
                    NGINX_HTTPS_PORT=8600
                    save_prompt "NGINX_HTTPS_PORT"
                elif [ "${SELECTIONSILENT[k]}" = "reporting" ]
                then
                    prompt_validnumber OSP_REPLICA_COUNT
                    RPT_SERVER_HOSTNAME="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "RPT_SERVER_HOSTNAME"
                    RPT_TOMCAT_HTTPS_PORT=443
                    save_prompt "RPT_TOMCAT_HTTPS_PORT"
		    prompt "ENABLE_CUSTOM_CONTAINER_CREATION"
		    if [ "$ENABLE_CUSTOM_CONTAINER_CREATION" == "n" ]
		    then
			USER_CONTAINER="o=data"
			save_prompt "USER_CONTAINER"
			ADMIN_CONTAINER="o=data"
			save_prompt "ADMIN_CONTAINER"
		    fi
                    if [ -z $SSO_SERVER_HOST ]
                    then
                        SSO_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                        save_prompt "SSO_SERVER_HOST"
                        SSO_SERVER_SSL_PORT=443
                        save_prompt "SSO_SERVER_SSL_PORT"
                    fi
                    FOR_SSPR_CONTAINER="y"
                    save_prompt "FOR_SSPR_CONTAINER"
                    SSPR_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "SSPR_SERVER_HOST"
                elif [ "${SELECTIONSILENT[k]}" = "idconsole" ]
                then
                    prompt_validnumber OSP_REPLICA_COUNT
                    ID_CONSOLE_SERVER_HOST="$IDM_ACCESS_VIA_SINGLE_DOMAIN"
                    save_prompt "ID_CONSOLE_SERVER_HOST"
                    ID_CONSOLE_SERVER_SSL_PORT=443
                    save_prompt "ID_CONSOLE_SERVER_SSL_PORT"
                fi
            done
        fi
        # Get the user inputs..
        for (( k = 0 ; k < $COUNTSILENT ; k++ ))
        do

            if [ "${SELECTIONSILENT[k]}" = "IDM" ]
            then
                save_prompt "INSTALL_ENGINE"
                save_prompt "INSTALL_IDVAULT"
                IS_IDM_CFG_SELECTED=1
#                source IDVault/scripts/prompts.sh
                source IDM/scripts/prompts.sh
            elif [ "${SELECTIONSILENT[k]}" = "IDMRL" ]
            then
                save_prompt "INSTALL_RL"
            elif [ "${SELECTIONSILENT[k]}" = "IDMFO" ]
            then
                save_prompt "INSTALL_FOA"
            elif [ "${SELECTIONSILENT[k]}" = "user_application" ]
            then
                save_prompt "INSTALL_UA"
                save_prompt "INSTALL_OSP"
                save_prompt "INSTALL_SSPR"
                if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
                then
                    source activemq/scripts/prompts.sh
                fi
                source osp/scripts/prompts.sh
                source sspr/scripts/prompts.sh
                source user_application/scripts/prompts.sh
                source user_application/scripts/prompts_fr.sh

                containsElement "reporting" "${SELECTIONSILENT[@]}"
                reportingselected=$?
                if [ $reportingselected -ne 0 ] && [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
                then
                # Removing reporting properties with osp container
                if [ -z "$RPT_PROMPT_NEEDED" ]
                then
                    RPT_PROMPT_NEEDED=n
                    save_prompt "RPT_PROMPT_NEEDED"
                fi
                fi

            elif [ "${SELECTIONSILENT[k]}" = "reporting" ]
            then
                save_prompt "INSTALL_REPORTING"
                save_prompt "INSTALL_OSP"
                if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
                then
                	save_prompt "INSTALL_SSPR"
		fi
                source osp/scripts/prompts.sh
                if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ]
                then
                	source sspr/scripts/prompts.sh
		fi
                source reporting/scripts/prompts.sh
                if [ ! -z "${DOCKER_CONTAINER}" ] && [ "${DOCKER_CONTAINER}" == "y" ] && [ "$IS_ADVANCED_EDITION" == "false" ]
                then
                  if [ -z "$UA_PROMPT_NEEDED" ]
                  then
                    UA_PROMPT_NEEDED=n
                    save_prompt "UA_PROMPT_NEEDED"
                  fi
                fi
            elif [ "${SELECTIONSILENT[k]}" = "iManager" ]
            then
                save_prompt "INSTALL_IMAN"
                source iManager/scripts/prompts.sh
            elif [ "${SELECTIONSILENT[k]}" = "idconsole" ] 
            then
                save_prompt "INSTALL_IDENTITY_CONSOLE"
                source idconsole/scripts/prompts.sh
            fi
        done
    fi

    cp $PROMPT_FILE $S_FILE_NAME
    
    if [ -z $TERRAFORM_GENERATE ] || [ "$TERRAFORM_GENERATE" == "n" ]
    then
      echo ""
      if [ -z ${KUBERNETES_ORCHESTRATION} ] || [ "${KUBERNETES_ORCHESTRATION}" == "n" ]
      then 
        info=`gettext install "Silent property file created at"`
        box_out "$info '$S_FILE_NAME'"
      fi
    fi
}


check_and_install_jre()
{
    if ! rpm -qa | grep -q netiq-jrex- ;  then
        disp_str=`gettext install "JRE is required for installation. Do you want to install JRE?"`
        prompt_yes_no "$disp_str"
        install_rpm "Java Runtime Environment" "netiq-jrex-*.rpm" "${IDM_INSTALL_HOME}common/packages/java" "${log_file}"
    fi

}


ask_file_name()
{

    local l_prompt=`gettext install "Enter silent property file name with absolute path:"`
    local l_default="/tmp/silent.properties"
    if [ "$DOCKER_CONTAINER" == "y" ]
    then
        l_default="/config/silent.properties"
    fi

    local VAL=""
    if [ ! -z "$AZURE_CLOUD" ] && [ "$AZURE_CLOUD" == "y" ]
    then
        VAL=""
    else
          read -e -p "${l_prompt} [ ${l_default}]:" VAL
    fi
          echo ""
          if [ "$VAL" == "" ]
          then
             VAL=$l_default

          fi
          if [ -f "$VAL" ] && [ -z "$AZURE_CLOUD" ]
          then
            disp_str=`gettext install "File %s already exists, do you want to overwrite ?"`
            disp_str=`printf "$disp_str" "$VAL"`
            prompt_yes_no "$disp_str" 
         fi
    S_FILE_NAME=$VAL

}


ask_directory_name()
{

    local l_prompt=`gettext install "Enter directory name with absolute path for creating kube deployment file:"`
    local l_default="/tmp/"

    local VAL=""
    read -e -p "${l_prompt} [ ${l_default}]:" VAL
    if [ "$VAL" == "" ]
    then
        VAL=$l_default
    fi
    S_DIR_NAME=$VAL
}


configure_products()
{
    parse_install_params $*
    DT=`date`
    PWD=`pwd`

    remove_prompt_file
    init_prompts ${IDM_INSTALL_HOME}common/conf/prompts.conf

    configure_interactive

    clean_pass_conf
    
    backup_prompt_conf
    
    cd $PWD
}

set_log_file "${LOG_FILE_NAME}"
configure_products $*

if [ ! -z $TERRAFORM_GENERATE ] && [ "$TERRAFORM_GENERATE" == "y" ] && [ ! -z $AZURE_CLOUD ] && [ "$AZURE_CLOUD" == "y" ]
then
    looplimit=5
    if [ true ]
    then
        serviceprincipal_info=`gettext install "Identity Manager deployment on Azure requires a Service Principal to manage the cloud infrastructure. Use the Azure CLI or any other supported modes for generating the Principal ID and Password. For more details, see the Azure documentation. You can also refer to the architecture of IDM containers deployment in Azure before proceeding further."`
        display_info "${serviceprincipal_info}"
        echo ""
        looplimit=5
        PROMPT_SAVE="false"
        while [ $looplimit -gt 0 ]
        do
            prompt SERVICE_PRINCIPAL_ID
            prompt_pwd SERVICE_PRINCIPAL_PWD noconfirm force
            prompt TENANT_ID
            az login --service-principal -u $SERVICE_PRINCIPAL_ID --password $SERVICE_PRINCIPAL_PWD --tenant $TENANT_ID --allow-no-subscriptions &> /dev/null
            valueofexit=$(echo $?)
            if [ $valueofexit -ne 0 ]
            then
                az_warning_msg=`gettext install "Entered Service Principal credentials seems to be wrong. Re-try"`
                echo_sameline "${txtylw}"
                write_and_log " ${az_warning_msg}"
                echo_sameline "${txtrst}"
            else
                break
            fi
            if [ $looplimit -eq 1 ]
            then
                looplimitexceed=`gettext install "Service Principal credentials tried 5 times but is failing for some reason.  Try running az login with service principal outside of this script and check.  Exiting..."`
                echo_sameline "${txtylw}"
                write_and_log " ${looplimitexceed}"
                echo_sameline "${txtrst}"
                exit 1
            fi
            ((looplimit--))
        done
        save_prompt "SERVICE_PRINCIPAL_ID"
        save_prompt "SERVICE_PRINCIPAL_PWD"
        save_prompt "TENANT_ID"
        looplimit=5
        PROMPT_SAVE="false"
        while [ $looplimit -gt 0 ]
        do
            prompt AZURE_CONTAINER_REGISTRY_SERVER
            prompt AZURE_ACR_USERNAME
            prompt_pwd AZURE_ACR_PWD noconfirm force
            docker login --username $AZURE_ACR_USERNAME --password $AZURE_ACR_PWD $AZURE_CONTAINER_REGISTRY_SERVER &> /dev/null
            valueofexit=$(echo $?)
            if [ $valueofexit -ne 0 ]
            then
                az_warning_msg=`gettext install "Entered Azure Container Registry credentials seems to be wrong. Re-try"`
                echo_sameline "${txtylw}"
                write_and_log " ${az_warning_msg}"
                echo_sameline "${txtrst}"
            else
                break
            fi
            if [ $looplimit -eq 1 ]
            then
                looplimitexceed=`gettext install "Docker login credentials tried 5 times but is failing for some reason.  Try running docker login outside of this script and check.  Exiting..."`
                echo_sameline "${txtylw}"
                write_and_log " ${looplimitexceed}"
                echo_sameline "${txtrst}"
                exit 1
            fi
            ((looplimit--))
        done
        save_prompt "AZURE_CONTAINER_REGISTRY_SERVER"
        save_prompt "AZURE_ACR_USERNAME"
        save_prompt "AZURE_ACR_PWD"
        looplimit=5
        PROMPT_SAVE="false"
        while [ $looplimit -gt 0 ]
        do
            az login --use-device-code
            valueofexit=$(echo $?)
            #echo "valueofexit is $valueofexit"
            if [ $valueofexit -ne 0 ]
            then
                az_warning_msg=`gettext install "Azure login seems to have failed. Re-try"`
                echo_sameline "${txtylw}"
                write_and_log " ${az_warning_msg}"
                echo_sameline "${txtrst}"
            else
                prompt AZURE_ACCOUNT_ID
                az account set --subscription $AZURE_ACCOUNT_ID
                if [ $? -ne 0 ]
                then
                    continue
                fi
                break
            fi
            if [ $looplimit -eq 1 ]
            then
                looplimitexceed=`gettext install "Azure login tried 5 times but is failing for some reason.  Try running az login outside of this script and check.  Exiting..."`
                echo_sameline "${txtylw}"
                write_and_log " ${looplimitexceed}"
                echo_sameline "${txtrst}"
                exit 1
            fi
            ((looplimit--))
        done
        save_prompt "AZURE_ACCOUNT_ID"
        looplimit=5
        PROMPT_SAVE="false"
        while [ $looplimit -gt 0 ]
        do
            prompt AZURE_RESOURCE_GROUP_NAME
            prompt AZURE_RESOURCE_GROUP_LOCATION
            az group create --name "${AZURE_RESOURCE_GROUP_NAME}" -l "${AZURE_RESOURCE_GROUP_LOCATION}" > /dev/null
            valueofexit=$(echo $?)
            if [ $valueofexit -ne 0 ]
            then
                az_warning_msg=`gettext install "Entered resource group location seems to be wrong. Re-try"`
                echo_sameline "${txtylw}"
                write_and_log " ${az_warning_msg}"
                echo_sameline "${txtrst}"
            else
                break
            fi
            if [ $looplimit -eq 1 ]
            then
                looplimitexceed=`gettext install "Resource group creation tried 5 times but is failing for some reason.  Refer Azure documentation for correct location name.  Exiting..."`
                echo_sameline "${txtylw}"
                write_and_log " ${looplimitexceed}"
                echo_sameline "${txtrst}"
                exit 1
            fi
            ((looplimit--))
        done
        save_prompt "AZURE_RESOURCE_GROUP_NAME"
        save_prompt "AZURE_RESOURCE_GROUP_LOCATION"
        info=`gettext install "Created Azure Resource Group:"`
        display_info "$info '${AZURE_RESOURCE_GROUP_NAME}' in location '${AZURE_RESOURCE_GROUP_LOCATION}'"
        source_prompt_file
        if [ "$KUBERNETES_ORCHESTRATION" == "y" ]
        then
            values_yaml_generation_info=`gettext install "Generating Configuration Files ... "`
            display_info "$values_yaml_generation_info"
            echo ""
            generate_helm_values_yaml
            if [ -z $TERRAFORM_GENERATE ] || [ "$TERRAFORM_GENERATE" == "n" ]
            then 
                echo ""
                info=`gettext install "Configuration files created at"`
                box_out "$info '/config'"
            fi
        fi        
        #Pushing the values to Azure Key Vault
        info=`gettext install "Creating Azure Key Vault:"`
        display_info "$info '${AZURE_KEYVAULT}'"
        az keyvault create --name "${AZURE_KEYVAULT}" --resource-group "${AZURE_RESOURCE_GROUP_NAME}" --location "${AZURE_RESOURCE_GROUP_LOCATION}" --no-self-perms false > /dev/null
        
        info=`gettext install "Uploading Identity Manager Configuration to Azure Key Vault"`
        display_info "$info"
	
        if [ "$IS_COMMON_PASSWORD" == "y" ] 
        then
          az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "idm-common-password" --value "$COMMON_PASSWORD" > /dev/null & spinner $!
        else

          if [ ! -z "$INSTALL_ENGINE" ] && [ "$INSTALL_ENGINE" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "id-vault-password" --value "$ID_VAULT_PASSWORD" > /dev/null & spinner $!
          fi

          if [ ! -z "$INSTALL_OSP" ] && [ "$INSTALL_OSP" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "sso-service-password" --value "$SSO_SERVICE_PWD" > /dev/null & spinner $!
          fi

          if [ ! -z "$INSTALL_UA" ] && [ "$INSTALL_UA" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "ua-admin-password" --value "$UA_ADMIN_PWD" > /dev/null & spinner $!
          fi

          if [ ! -z "$INSTALL_REPORTING" ] && [ "$INSTALL_REPORTING" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "rpt-admin-password" --value "$RPT_ADMIN_PWD" > /dev/null & spinner $!
          fi

          if [ ! -z "$INSTALL_SSPR" ] && [ "$INSTALL_SSPR" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "sspr-configuration-passsword" --value "$CONFIGURATION_PWD" > /dev/null & spinner $!
          fi

        fi
  
        if [ ! -z "$AZURE_POSTGRESQL_REQUIRED" ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
        then

          export dbadminloginpass=$(vmanddbpwdupper 5)$(get_14_digit_random_number 2)$(vmanddbpwdlower 5)$(get_14_digit_random_number 2)
          az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "dbadminloginpass" --value "$dbadminloginpass" > /dev/null & spinner $!
          az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "rptdbusersharepwd" --value "$dbadminloginpass" > /dev/null & spinner $!

          export uawfedbuserpwd=$(vmanddbpwdupper 5)$(get_14_digit_random_number 2)$(vmanddbpwdlower 5)$(get_14_digit_random_number 2)
          az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "uawfedbuserpwd" --value "$uawfedbuserpwd" > /dev/null & spinner $!
          
        else

          if [ ! -z "$INSTALL_UA" ] && [ "$INSTALL_UA" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "ua-wfe-db-pwd" --value "$UA_WFE_DATABASE_PWD" > /dev/null & spinner $!
          fi

          if [ ! -z "$INSTALL_REPORTING" ] && [ "$INSTALL_REPORTING" == "true" ]
          then
              az keyvault secret set --vault-name "${AZURE_KEYVAULT}" --name "rpt-db-shared-pwd" --value "$RPT_DATABASE_SHARE_PASSWORD" > /dev/null & spinner $!
          fi

        fi
    
    
        openssl pkcs12 -export -out /config/tls.pfx -inkey ${IDM_ACCESS_SINGLE_DOMAIN_KEY_FILE} -in ${IDM_ACCESS_SINGLE_DOMAIN_CRT_FILE} -passout pass:'' &> /dev/null
        az keyvault certificate import --vault-name "${AZURE_KEYVAULT}" -n "ingress-tls-crt" -f "/config/tls.pfx" &> /dev/null & spinner $!

    fi

    rm -rf silent.properties
    rm -rf secret.properties

    # Creating Azure storage account for saving the terraform state files
    fourteendigitnumberforstorage=$(get_14_digit_random_number)
    AZURE_STORAGE_ACCOUNT_FOR_TFSTATE=`echo stract${fourteendigitnumberforstorage}`
    az storage account create --name "${AZURE_STORAGE_ACCOUNT_FOR_TFSTATE}" --resource-group "${AZURE_RESOURCE_GROUP_NAME}" --location "${AZURE_RESOURCE_GROUP_LOCATION}" --sku Standard_LRS --encryption-services blob &> /dev/null & spinner $!
    az storage container create -n terraform-state --account-name "${AZURE_STORAGE_ACCOUNT_FOR_TFSTATE}" &> /dev/null & spinner $!
    echo ""
fi

# Creating terraform
if [ ! -z $TERRAFORM_GENERATE ] && [ "$TERRAFORM_GENERATE" == "y" ]
then
    rm -rf /config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files
    cp -rpf /azure/IDM_Azure_Terraform_Configuration /config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files
    cp -rpf /config/values.yaml /config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files/
    cp -rpf /config/values.yaml /config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files/modules/values_yaml/
    rm -rf /config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files/data_containers.ldif
    tfvarsfile=/config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files/terraform.tfvars
    ##### Editing main.tf file for backend info as variables are not allowed within Terraform during this stage ####
    maintffile=/config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files/main.tf
    search_and_replace "__AZURE_RESOURCE_GROUP_NAME__" $AZURE_RESOURCE_GROUP_NAME "$maintffile"
    search_and_replace "__AZURE_TFSTATE_STORAGE_ACCOUNT_NAME__" $AZURE_STORAGE_ACCOUNT_FOR_TFSTATE "$maintffile"
    ##### Editing main.tf file for backend info as variables are not allowed within Terraform during this stage ####
    if [ ! -z "$AZURE_POSTGRESQL_REQUIRED" ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
    then
        search_and_replace "__AZURE_POSTGRESQL_SERVER_DEPLOY__" true "$tfvarsfile"
        search_and_replace "__AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM__" $AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM "$tfvarsfile"
    else
        search_and_replace "__AZURE_POSTGRESQL_SERVER_DEPLOY__" false "$tfvarsfile"
        search_and_replace "__AZURE_POSTGRESQL_SERVER_NAME_TERRAFORM__" "" "$tfvarsfile"
    fi
    search_and_replace "__AZURE_KEYVAULT__" $AZURE_KEYVAULT "$tfvarsfile"
    search_and_replace "__AZURE_KEYVAULT_EXISTS__" true "$tfvarsfile"
    search_and_replace "__AZURE_RESOURCE_GROUP_NAME__" $AZURE_RESOURCE_GROUP_NAME "$tfvarsfile"
    search_and_replace "__AZURE_RESOURCE_GROUP_EXISTS__" true "$tfvarsfile"
    search_and_replace "__AZURE_CONTAINER_REGISTRY_SERVER__" $AZURE_CONTAINER_REGISTRY_SERVER "$tfvarsfile"
    search_and_replace "__KUBERNETES_NAMESPACE__" $KUBERNETES_NAMESPACE "$tfvarsfile"
    search_and_replace "__AZURE_ACR_USERNAME__" $AZURE_ACR_USERNAME "$tfvarsfile"
    search_and_replace "__AZURE_ACR_PWD__" $AZURE_ACR_PWD "$tfvarsfile"
    search_and_replace "__AZURE_RESOURCE_GROUP_LOCATION__" $AZURE_RESOURCE_GROUP_LOCATION "$tfvarsfile"
    cd /config
    
    #if [ ! -z "$AZURE_POSTGRESQL_REQUIRED" ] && [ "$AZURE_POSTGRESQL_REQUIRED" == "y" ]
    #then
    #  cat /idm/Terraform/azure_pg_conf >> /config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files/main.tf 
    #fi

    tar_info=`gettext install "Creating Terraform configuration archive"`
    display_info "$tar_info 'IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files.zip'"
    chmod -R 755 IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files
    7z a -tzip IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files.zip IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files > /dev/null
    rm -rf IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files
    echo ""
    info=`gettext install "Terraform configuration archive created at"`
    box_out "$info '/config/IDM_${CURRENT_IDM_VERSION}_Cloud_Deployment_files.zip'" 
    rm -rf silent.properties
    rm -rf secret.properties
    rm -rf values.yaml   
fi

