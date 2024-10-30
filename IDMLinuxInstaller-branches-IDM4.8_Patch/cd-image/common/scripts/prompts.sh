#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. gettext.sh
declare -a prompt_ids
declare -a prompt_types
declare -a prompt_questions
declare -a prompt_defaults
declare -a prompt_values
declare -a prompt_comments

declare return_value
declare prompt_init_done="N"
declare is_already_processed="N"
#declare IS_ADVANCED_MODE="false"

txtred=$(tput setaf 1)
txtrst=$(tput sgr0) 
txtylw=$(tput setaf 3)

PROMPT_SAVE="true"

init_prompts()
{

local filename="$1"
local index=0;
if [ ! -d "${IDM_TEMP}" ]
then
mkdir "${IDM_TEMP}"
fi
[ $IS_UPGRADE -ne 1 ] && remove_prompt_file
while read -r line
do
    local name=`echo $line`

    if [[ $name == \#* || $name == "" ]]    
    then
      continue
    fi

    IFS='|' read -ra token <<< "$name"
    local id=`echo ${token[0]}`
    local prompt_type=`echo ${token[1]}`
    local default=`echo ${token[2]}`
    local question=`echo ${token[3]}`
    local comment=`echo ${token[4]}`

    prompt_ids[$index]=$id
    prompt_types[$index]=$prompt_type
    prompt_questions[$index]=$question
    prompt_defaults[$index]=$default
    prompt_values[$index]=""
    prompt_comments[$index]=$comment

    index=`expr $index + 1`
done < "$filename"

    source_prompt_file
prompt_init_done="Y"

}

prompt_port()
{
#$4 contains host ip for the port, which helps to decide whether port check should be done or not
local IS_HOST_REMOTE=0
local def_val="-"
if [ -n "$2" ] && [ "$2" != "check" ]
then
    def_val=$2
fi
if [ -n "$4" ]
then
    local host_ip="$4"
    local ip_addr_list=( $(/sbin/ip -f inet addr list | grep -E '^[[:space:]]*inet' | sed -n '/127\.0\.0\./!p' | awk '{print $2}' | awk -F '/' '{print $1}') )
    containsElement "$host_ip" "${ip_addr_list[@]}"
    if [ $? -eq 1 ]
    then
         IS_HOST_REMOTE=1
    fi
fi
if [ $SKIP_PORT_CHECK -eq 1 ] || [ "$UPGRADE_IDM" == "y" ] || [ $IS_UPGRADE -eq 1 ] || [ "$CREATE_SILENT_FILE" == "true" ] || [ $IS_HOST_REMOTE -eq 1 ]
then
    prompt_internal $1 $def_val "port"
	return
else
	if [ $UNATTENDED_INSTALL -eq 1 ] && [ "$2" != "check"  ]
	then
	    return
	elif [ $UNATTENDED_INSTALL -ne 1 ]
	then
		eval "L=\$$1"
		if [ ! -z $L ]
		then
			return
		fi
	fi
	while(true)
	do
        prompt_internal $1 $def_val "port"
		eval "L=\$$1"
#		    netstat -tulpen | grep -w $L -q
		    ss -r -tulpen | grep -w $L -q
		ISPORTINUSE=$?
		if [ $ISPORTINUSE -eq 1 ]
		then
			break;
		#silent mode
		elif [ $UNATTENDED_INSTALL -eq 1 ]
		then
		    check_port_used_by_product $L
			if [ $? == 0 ]
			then 
			    break;
		    else
            str1=`gettext install "Error: Port %s(for %s) is already in use. Use a different port."`
			str1=`printf "$str1" "$L" "$1"`
			write_and_log "${str1}"
			exit 1
			fi
	    #typical mode
	    elif [ "$IS_ADVANCED_MODE" != "true" ]
        then
			check_port_used_by_product $L
			if [ $? == 0 ]
			then 
			    break;
		    else
            str1=`gettext install "Port %s(for %s) is already in use. Enter a different port."`
			str1=`printf "$str1" "$L" "$1"`
            echo_sameline "${txtred}"
			write_and_log "${str1}"
			echo_sameline "${txtrst}"
			return_value="set_to_null"
			fi
        #custom mode
	    elif [ "$IS_ADVANCED_MODE" == "true" ]
	    then
			check_port_used_by_product $L
			if [ $? == 0 ]
			then 
			    break;
		    else
            str1=`gettext install "Port %s(for %s) is already in use. Enter a different port."`
			str1=`printf "$str1" "$L" "$1"`
            echo_sameline "${txtred}"
			write_and_log "${str1}"
			echo_sameline "${txtrst}"
			var_val="set_to_null"
			fi
		fi	
	done
fi
}

check_port_used_by_product(){
	file1=/opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties
	file2=/opt/netiq/idm/postgres/data/postgresql.conf
#	    ldaps=$(netstat -tulpen | grep -w $1 | awk '{print $9}' | cut -d/ -f2)
	    ldaps=$(ss -r -tulpen | grep -m1 -w $1 | awk '{print $7}' | cut -d: -f2 | cut -d, -f1 | sed -e 's/(("\(.*\)"/\1/')
	if [ "$ldaps" == "ndsd" ]
	then
		return 0
	fi
    if [ -e $file1 ]
	then
		C=$(grep -E 'http:|https:' /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties | while read -r line; 
			do
			    echo $line | cut -d: -f2,3 | grep : -q
				if [ $? -eq 0 ]
				then
					portlist=$(echo $line | grep : | cut -d: -f3 | cut -d/ -f1)
				echo $portlist
				fi
			done)
		C=$(echo $C | tr ' ' '\n' | sort -nu)
		containsElement $1 $C
		if [ $? == 0 ]
		then
			return 0
		fi
	fi
	#check for the entry in postgresql.conf
	if [ -e $file2 ]
	then
		ispresent="port = $1"
		grep -q "$ispresent" $file2
		if [ $? -eq 0 ]
		then
			return 0
		fi
	fi
	
	return 1
}

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

prompt()
{
    local default="-"

    if [ "$2" != "" ]
    then
      default=$2

    fi
    if [ "$3" == "" ]
    then
        prompt_internal $1 $default "-" 
    else
        prompt_internal $1 $default $3
    fi 
}


prompt_pwd()
{
    local default="-"
	if [ "$1" != "COMMON_PASSWORD" ] && [ "$3" != "force" ] && [ -n "$IS_COMMON_PASSWORD" ] && [[ "$IS_COMMON_PASSWORD" =~ ^[yY]$ ]] && [ "$2" == "confirm" ]
	then
		eval "$1='${COMMON_PASSWORD}'"
		save_prompt $1
    else
    	if [ "$2" == "confirm" ]
		then
		    prompt_internal $1 $default "pwd_confirm"
        else
			prompt_internal $1 $default "pwd"
		fi
	fi
}

save_prompt()
{
local id=$1
local index=0
local default="true"

    for pid in "${prompt_ids[@]}"
    do

        if [ "$pid" == "$id" ]
        then
           eval "var_val=\$$id"
          local value=${prompt_values[$index]}
          if [ -z "$value" ]
          then
              value=$var_val
          fi

           if [ ! -z "$value" ]
           then
            #  local value=$var_val
              is_already_processed="N"
              PROMPT_SAVE="true"
	      if [ "$var_val" != "$value" ]
	      then
              write_prompt_data $index $id "$var_val"
	      else
              write_prompt_data $index $id "$value"
	      fi
              return
           elif [ ! -z "$default" ]
           then
                write_prompt_data $index $id $default
                is_already_processed="N"
                PROMPT_SAVE="true"

           else
             disp_str=`gettext install "Value not set for variable %s"`
             disp_str=`printf "$disp_str" "${id}"`
             write_and_log "$disp_str"
             exit 1
          fi
        fi
    index=`expr $index + 1`
    done


}


write_prompt_data()
{

local index_1=$1
local id_1=$2
local value="$3"

    local comment=${prompt_comments[$index_1]}
    prompt_values[$index_1]="$value"
    if [ "$is_already_processed" != "Y" -a "$PROMPT_SAVE" == "true" ]
    then
        if [ "$comment" != "" ]
        then
	    if [ ! -f "$PROMPT_FILE" ]
	    then
	    	if [ ! -z "$IDM_TEMP" ]
		then
			mkdir -p "$IDM_TEMP"
		fi
		touch "$PROMPT_FILE"
	    fi
	    source "$PROMPT_FILE"
    	    if [ ! -z "\$$id_1" ]
	    then
		grep "$id_1" $PROMPT_FILE | grep -q "$id_1=\"${value}\""
		if [ $? -eq 0 ]
		then
			#Already same value for the variable is present
			#Duplicate Value is avoided
			return
		fi
	    fi
            echo " "  >> $PROMPT_FILE
            echo "###" >> $PROMPT_FILE
            disp_str="`gettext install \"${comment}\"`"
            echo "# $disp_str" >> $PROMPT_FILE
            echo "### "  >> $PROMPT_FILE
        fi
        echo "$id_1=\"${value}\"" >> $PROMPT_FILE
        source_prompt_file 
    else
        eval "$id_1=\"${value}\"" 
    fi

}


prompt_internal()
{
    local id=$1
    local pass=$3
    local p_default=$2
    local index=0
    local ret="null"


    for pid in "${prompt_ids[@]}"
    do
        if [ "$pid" == "$id" ]
        then 
            read_single_prompt $id $index $pass $p_default
            if [[ "$id" == "TOMCAT_SSL_KEYSTORE_PASS" ]] || [[ "$id" == "IDM_KEYSTORE_PWD" ]] || [[ "$id" == *"PWD"* ]] || [ "$id" == "COMMON_PASSWORD" ] && [ ${#return_value} -lt 6 ] && [[ "$id" != "UA_WFE_DATABASE_PWD" ]] && [[ "$id" != "UA_WFE_DATABASE_ADMIN_PWD" ]]
            then
            echo_sameline "${txtylw}"
            write_and_log ""
	    passstr=`gettext install "Password must be 6 characters long. Please provide a correct one."`
            write_and_log "$passstr"
            write_and_log ""
            echo_sameline "${txtrst}"
            prompt_internal $*
	    elif [ "$id" == "ID_VAULT_TREENAME" ] && [ ${#return_value} -gt 32 ]
	    then
	    echo_sameline "${txtylw}"
	    write_and_log ""
	    treechar=`gettext install "Tree name should not exceed 32 characters. Please provide a correct one."`
	    write_and_log "$treechar"
	    prompt_internal $*
        elif [ "$id" == "AZURE_DOCKER_VM_HOST_NAME" ] && [[ ${return_value} =~ [^a-zA-Z0-9] || -z "${return_value}" ]]
        then
            echo_sameline "${txtylw}"
            write_and_log ""
            hostchar=`gettext install "Host name contains special characters. Please provide only alphanumeric characters."`
            write_and_log "$hostchar"
            echo_sameline "${txtrst}"
            prompt_internal $*
	    elif [ "$id" == "ID_VAULT_SERVERNAME" ]
	    then
            if [ ${#return_value} -gt 32 ]
            then
                echo_sameline "${txtylw}"
                write_and_log ""
                serverchar=`gettext install "Server name should not exceed 32 characters. Please provide a correct one."`
                write_and_log "$serverchar"
                echo_sameline "${txtrst}"
                prompt_internal $*
            fi
            # checking if it has special chars
            if [[ ${return_value} =~ [^a-zA-Z0-9._] || -z "${return_value}" ]]
            then
                echo_sameline "${txtylw}"
                write_and_log ""
                serverchar=`gettext install "IDVault Server name contains special characters. Please provide only accepted values"`
                write_and_log "$serverchar"
                echo_sameline "${txtrst}"
                prompt_internal $*
            fi
            # checking if it starts with dot
            echo ${return_value} | grep -vq ^[^.].*$
            if [ $? -eq 0 ]
            then
                echo_sameline "${txtylw}"
                write_and_log ""
                serverchar=`gettext install "IDVault Server name starts with dot. Please provide only accepted values"`
                write_and_log "$serverchar"
                echo_sameline "${txtrst}"
                prompt_internal $*
            fi
	    write_prompt_data $index $id "$return_value"
        else
            write_prompt_data $index $id "$return_value"
        fi


#            eval "$id=$return_value"
#	    local comment=${prompt_comments[$index]}
#            prompt_values[$index]=$return_value
#            if [ "$is_already_processed" != "Y" -a "$PROMPT_SAVE" == "true" ]
#            then
#            write_prompt_data $index $id "$return_value"
#               if [ "$comment" != "" ]
#                then
#                    echo " "  >> $PROMPT_FILE
#   	            echo "###" >> $PROMPT_FILE
#	            echo "# $comment" >> $PROMPT_FILE
#                    echo "### "  >> $PROMPT_FILE
#                fi
#                echo "$id=$return_value" >> $PROMPT_FILE
#                source_prompt_file
#           fi
            return
        fi
        index=`expr $index + 1`  
    done
    disp_str=`gettext install "Could not find prompt ID: %s"`
    disp_str=`printf "$disp_str" "${id}"`
    write_and_log "$disp_str"
    exit 1 
}


read_single_prompt()
{
    
    local id=$1
    local index=$2
    local pass=$3
    local p_default=$4
    local prompt=${prompt_questions[$index]}
    local default="${prompt_defaults[$index]}"
    if [ "${default}" == "127.0.0.1" ]
    then
        local tmpdefault=
        if [ -f ${SINGLE_IP_SAVE_FILE} ]
        then
            tmpdefault=`cat ${SINGLE_IP_SAVE_FILE} | cut -d"=" -f2`
        fi
        if [ -z "${tmpdefault}" ] && [ -f ${IP_SAVE_FILE} ]
        then
            tmpdefault=`cat ${IP_SAVE_FILE} | cut -d"=" -f2`
        fi
        if [ ! -z "${tmpdefault}" ]
        then
            default=${tmpdefault}
        fi
    fi
    local value=${prompt_values[$index]}
    local prompt_type=${prompt_types[$index]}

    IFS=',' read -ra typetoken <<< "$prompt_type"
    local prompt_type=`echo ${typetoken[0]}`
    local upgrade_prompt_type=`echo ${typetoken[1]}`
    if [ "$upgrade_prompt_type" != "" ] && [ "$upgrade_prompt_type" != "UP" ]
    then
    	disp_str=`gettext install "UP expected as second option with prompt_type"`
	write_and_log "$disp_str"
	exit 1
    fi
    local upgrade_prompt="false"
    if [ "$prompt_type" == "UP" ] || [ "$upgrade_prompt_type" == "UP" ]
    then
    	upgrade_prompt="true"
    fi
    
    is_already_processed="N"
    
    if [ "$p_default" != "-"  ]
    then
        default="$p_default"
    fi

    if [ "$var_val" == "set_to_null" ]
	then
	var_val=""
	
	else
    eval "var_val=\$$id"
	fi
	
		  
    if [ ! -z "$var_val" -a "$PROMPT_SAVE" == "true" ]
    then
		if [ "$return_value" != "set_to_null" ]
		then
			return_value=$var_val
			is_already_processed="Y"
            return
		fi
    fi

#    if [ ! -z "$value" ]
#    then
#       return_value=$value
#       return
#    fi
     

    if [ -z "${default}" ]
    then
       p_default=""
    else
       p_default="[$default]"
    fi

    if [ "$prompt_type" == "NP" ]
    then
       return_value=$default
       return
    fi

    #
    # Advanced prompt should have default promot, else thru error.
    #
    if [  "$prompt_type" == "AP" -a  "$default" == "" ]
    then
       disp_str=`gettext install "No default value found for %s"`
       disp_str=`printf "$disp_str" "${id}"`
       write_and_log "$disp_str"
       exit 1
    fi



    #
    # Typical mode of configuration selected and those prompt having advanced, shoud use default.
    #
    if [ "$IS_ADVANCED_MODE" != "true" -a  "$prompt_type" == "AP" ]
    then
    	if [ "$upgrade_prompt" == "true" -a "$UPGRADE_IDM" == "y" ] || [ "$CFG_MODE" == "advanced" -a "$UPGRADE_IDM" == "n" ]
		then
			echo "Let it pass through" &> /dev/null
		else
			if [ "$return_value" == "set_to_null" ]
			then
				return_value=""
			else
				return_value=$default
				if [ "$pass" == "ndsData" ] && [ "$IS_ADVANCED_MODE" != "true" ]
				then
					check_if_btrfs "$return_value"
					if [ $? -eq 0 ]
					then 
				        return
				     fi
		        else
					return
         		fi	
			fi
		fi
    fi


    if [ $UNATTENDED_INSTALL -eq 1 -a  -z "$var_val" ]
    then 
        disp_str=`gettext install "Value not set for silent variable %s"`
        disp_str=`printf "$disp_str" "${id}"`
        write_and_log "$disp_str"
        exit 1
    fi

    local VAL=""
    prompt_str="`gettext install \"${prompt}\"`"
    colon_str=`gettext install ":"`
        while [ "$VAL" == "" ]
        do
           if [ "$pass" == "pwd" ]
           then
               stty -echo
               default=""
               read -e -p "$prompt_str$colon_str" VAL      
			   write_and_log ""
           elif [ "$pass" == "pwd_confirm" ]
           then
               stty -echo
               default=""
               read -e -p "$prompt_str$colon_str" VAL      
               write_and_log ""
               disp_str=`gettext install "Confirm Password:"`
               read -e -p "$disp_str" CONFIRM_PASSWORD
               while [ "$VAL" != "$CONFIRM_PASSWORD" ]
               do
                   write_and_log ""
                   echo_sameline "${txtylw}"
                   disp_str=`gettext install "Passwords do not match. Enter the password again."`
                   write_and_log "$disp_str"
                   echo_sameline "${txtrst}"
                   write_and_log ""
                   write_and_log ""
                   read -e -p "$prompt_str$colon_str" VAL      
                   write_and_log "" 
                   disp_str=`gettext install "Confirm Password:"`
                   read -e -p "$disp_str" CONFIRM_PASSWORD
               done
			   write_and_log ""
               stty echo
           elif [ "$pass" == "file" ]
           then
                local file_exists=0
                while [ $file_exists -eq 0 ]
                do
                    read -e -p "$prompt_str ${p_default}$colon_str" VAL
                    if [ "$VAL" == "" ]
                    then
                        VAL=$default
                    fi
                    if [ -f $VAL ]
                    then
                        file_exists=1
                    else
                        disp_str=`gettext install "Error: The given file does not exist. Enter a valid file."`
                        echo_sameline "${txtred}"
                        write_and_log "$disp_str"
                        echo_sameline "${txtrst}"
                        write_and_log ""
                        if [ $UNATTENDED_INSTALL -eq 1 ]
                        then
                            disp_str=`gettext install "Exiting configuration due to invalid file path."`
                            write_log "$disp_str"
                            exit 1
                        fi
                    fi
                done
           elif [ "$pass" == "folder" ]
           then
                local folder_exists=0
                while [ $folder_exists -eq 0 ]
                do
                    read -e -p "$prompt_str ${p_default}$colon_str" VAL
                    if [ "$VAL" == "" ]
                    then
                        VAL=$default
                    fi
                    if [ -d $VAL ]
                    then
                        folder_exists=1
                    else
                        disp_str=`gettext install "Error: The given folder does not exist. Enter a valid folder."`
                        echo_sameline "${txtred}"
                        write_and_log "$disp_str"
                        echo_sameline "${txtrst}"
                        write_and_log ""
                        if [ $UNATTENDED_INSTALL -eq 1 ]
                        then
                            disp_str=`gettext install "Exiting configuration due to invalid folder path."`
                            write_log "$disp_str"
                            exit 1
                        fi
                    fi
                done
			elif [ "$pass" == "ndsData" ]
            then
                local btrfs_doesnot_exist=0
                while [ $btrfs_doesnot_exist -eq 0 ]
                do
                    read -e -p "$prompt_str ${p_default}$colon_str" VAL
                    if [ "$VAL" == "" ]
                    then
                        VAL=$default
                    fi
				    check_if_btrfs "$VAL"
					isbtrfs=$?
					if [ $isbtrfs -eq 1 ] && [ $UNATTENDED_INSTALL -eq 1 ]
					then
                        exit 1
					elif [ $isbtrfs -eq 0 ] 
					then
						btrfs_doesnot_exist=1
					fi
                done
           elif [ "$pass" == "port" ]
           then
                local is_input_valid=0
                while [ $is_input_valid -eq 0 ]
                do
                    read -e -p "$prompt_str ${p_default}$colon_str" VAL
                    if [ "$VAL" == "" ]
                    then
                        VAL=$default
                    fi
                    if [[ "$VAL" =~ ^[0-9]+$ ]]
                    then
                        is_input_valid=1
                    else
                        disp_str=`gettext install "Invalid Port: Enter a valid port."`
                        echo_sameline "${txtred}"
                        write_and_log "$disp_str"
                        echo_sameline "${txtrst}"
                        write_and_log ""
                        if [ $UNATTENDED_INSTALL -eq 1 ]
                        then
                            disp_str=`gettext install "Exiting configuration due to invalid value set for %s."`
                            disp_str=`printf "$disp_str" "$id"`
                            write_log "$disp_str"
                            exit 1
                        fi
                    fi
                done
           elif [ "$pass" == "validnumber" ]
           then
                local is_input_valid=0
                while [ $is_input_valid -eq 0 ]
                do
                    read -e -p "$prompt_str ${p_default}$colon_str" VAL
                    if [ "$VAL" == "" ]
                    then
                        VAL=$default
                    fi
		    #Removing leading zeros
		    VAL=$(echo $VAL | sed 's/^0*//')
                    if [[ "$VAL" =~ ^[0-9]+$ ]]
                    then
                        is_input_valid=1
                    else
                        disp_str=`gettext install "Enter a valid number that is greater than 0."`
                        echo_sameline "${txtred}"
                        write_and_log "$disp_str"
                        echo_sameline "${txtrst}"
                        write_and_log ""
                        if [ $UNATTENDED_INSTALL -eq 1 ]
                        then
                            disp_str=`gettext install "Exiting configuration due to invalid value set for %s."`
                            disp_str=`printf "$disp_str" "$id"`
                            write_log "$disp_str"
                            exit 1
                        fi
                    fi
                done
           elif [ "$pass" != "-" ]
           then
                IFS='/' read -r -a input_options <<< "$pass"
                flag=0
                while [ $flag -eq 0 ]
                do
                    read -e -p "$prompt_str ${p_default}$colon_str" VAL
                    if [ "$VAL" == "" ]
                    then
                        VAL=$default
                    fi
                    for option_value in "${input_options[@]}"
                    do
                        if [ "$option_value" == "$VAL" ]
                        then
                            flag=1
                            break
                        fi
                    done
                    if [ $flag -eq 0 ]
                    then
                        disp_str=`gettext install "Invalid Input: Enter a valid input."`
                        echo_sameline "${txtred}"
                        write_and_log "$disp_str"
                        echo_sameline "${txtrst}"
                        write_and_log ""
                        if [ $UNATTENDED_INSTALL -eq 1 ]
                        then
                            disp_str=`gettext install "Exiting configuration due to invalid value set for %s."`
                            disp_str=`printf "$disp_str" "$id"`
                            write_log "$disp_str"
                            exit 1
                        fi
                    fi
                done
           else
              read -e -p "$prompt_str ${p_default}$colon_str" VAL
           fi
          write_and_log ""
          if [ "$VAL" == "" ]
          then
             VAL="$default"
          fi
        done
stty echo
return_value="$VAL"

}

remove_prompt_file()
{

   if [  -f "$PROMPT_FILE" -a $IS_LICENSE_CHECK_DONE != "1" ]
   then
       rm $PROMPT_FILE
   elif [ ! -d "$IDM_TEMP"  ]
   then
       mkdir $IDM_TEMP
   fi

   DT=`date`
   if [ ! -z "$PRINTED_USAGE" ] && [ "$PRINTED_USAGE" == "true" ]
   then
   	return 0
   fi

   echo "# "  >> $PROMPT_FILE
   disp_str=`gettext install "# This is the silent property file created for installation or configuration of Identity Manager components."`
   echo "$disp_str"  >> $PROMPT_FILE
   disp_str=`gettext install "# Copyright (c) Microfocus"`
   echo "$disp_str"  >> $PROMPT_FILE
   echo "# "  >> $PROMPT_FILE
   disp_str=`gettext install "# Date: %s"`
   disp_str=`printf "$disp_str" "$DT"`
   echo "$disp_str"  >> $PROMPT_FILE
   echo "# "  >> $PROMPT_FILE
   disp_str=`gettext install "# Usage:"`
   echo "$disp_str"  >> $PROMPT_FILE
   echo "#       install.sh/configure.sh -s -f <silent property file>"  >> $PROMPT_FILE
   echo "# "  >> $PROMPT_FILE
   disp_str=`gettext install "# Use create_silent_props.sh to create this file. Avoid editing this file manually"`
   echo "$disp_str"  >> $PROMPT_FILE
   echo "# "  >> $PROMPT_FILE
   disp_str=`gettext install "# Log files can be found at %s during execution."`
   disp_str=`printf "$disp_str" "/var/opt/netiq/idm/log"`
   echo "$disp_str"  >> $PROMPT_FILE
   echo "# "  >> $PROMPT_FILE
   export PRINTED_USAGE=true


}


source_prompt_file()
{
   if [  -f "$PROMPT_FILE" ]
   then
       . $PROMPT_FILE
    fi
    [ $UNATTENDED_INSTALL -eq 1 ] && [ -f "${FILE_SILENT_INSTALL}" ] && source "${FILE_SILENT_INSTALL}"
}


prompt_yes_no()
{
    local prompt_val=$1
    prompt_id='y'
    write_and_log ""
    write_and_log $prompt_val
    str1=`gettext install "To continue, type (y or n) and then ENTER  [default: %s]:"`
    str1=`printf "$str1" "$prompt_id"`
    read -e -p "$str1" prompt_id
    write_and_log ""
    if [ -z "${prompt_id}" ]; then prompt_id='y'; fi
    if [ "${prompt_id}" != 'y' -a "${prompt_id}" != 'Y' ]
    then
        write_and_log ""
        echo_sameline "${txtred}"
        str1=`gettext install "Terminating the program..."`
        write_and_log "${str1}"
        echo_sameline "${txtrst}"
        write_and_log ""
        exit 1
    fi
}


prompt_stand_advan()
{
    if [ ! -z "$promptsforRLonly" ] && [ "$promptsforRLonly" == "true" ]
    then
    	VAL="true"
    	return
    fi

    local prompt_val=$1
    local prompt_id='A'
    VAL=""

    # Remove any residual file due to incomplete install
    if [ -f /etc/opt/netiq/idm/configure/advanced ]
    then
        rm /etc/opt/netiq/idm/configure/advanced
    fi

    while [ "$VAL" == ""  ]
    do
        prompt_id="y"
	if [ -z "$prompt_val" ]
	then
        	str1=`gettext install "Do you want to install Advanced Edition of Identity Manager server? To confirm, type y. To install the Standard Edition, type n. [default: %s]:"`
	elif [ "$prompt_val" == "configure" ]
	then
        	str1=`gettext install "Do you want to configure Advanced Edition of Identity Manager server? To confirm, type y. To configure the Standard Edition, type n. [default: %s]:"`
	fi
        str1=`printf "$str1" "$prompt_id"`
        read -e -p "${str1}" prompt_id
    
        if [ "${prompt_id}" = 'n' ]
	    then
            VAL="false"
	    break 
	    fi   
        if [ "${prompt_id}" = "" -o "${prompt_id}" = 'y' ]
        then
        VAL="true"
        [ ! -d /etc/opt/netiq/idm/configure/ ] && mkdir -p /etc/opt/netiq/idm/configure/ && touch /etc/opt/netiq/idm/configure/advanced
        break
        fi  
        str2=`gettext install "Invalid option. Type y or n"`
        write_and_log "${str2}"
    done

}

prompt_check_upgrade()
{
    local prompt_val=$1
    
    VAL=""
    while [ "$VAL" == ""  ]
    do
    	local prompt_id='n'
        str1=`gettext install "Do you want to upgrade the existing Identity Manager components (y/n)? [default: %s]:"`
        str1=`printf "$str1" "$prompt_id"`
    	read -e -p "$str1" prompt_id
    
        if [ "${prompt_id}" = "" -o "${prompt_id}" = 'n' -o "${prompt_id}" = 'N' ]
	    then
            UPGRADE_IDM="n"
	        return
	    elif [ "${prompt_id}" = 'y' -o "${prompt_id}" = 'Y' ]
	    then
	        UPGRADE_IDM="y"
		IS_UPGRADE=1
	        return
	    fi
	    str2=`gettext install "Invalid option. Type y or n"`
	    write_and_log "${str2}"
    done
}

sspr_prompt_check_upgrade()
{

    local prompt_val=$1

    VAL=""
    while [ "$VAL" == ""  ]
    do
        local prompt_id='n'
        str1=`gettext install "Do you want to upgrade the existing Self Service Password Reset (SSPR) (y/n)? [default: %s]:"`
        str1=`printf "$str1" "$prompt_id"`
        read -e -p "$str1" prompt_id

        if [ "${prompt_id}" = "" -o "${prompt_id}" = 'n' -o "${prompt_id}" = 'N' ]
            then
            UPGRADE_IDM="n"
                return
            elif [ "${prompt_id}" = 'y' -o "${prompt_id}" = 'Y' ]
            then
                UPGRADE_IDM="y"
                IS_UPGRADE=1
                return
            fi
            str2=`gettext install "Invalid option. Type y or n"`
            write_and_log "${str2}"
    done
}


obtain_path()
{

    local backupPath=
    
    VAL=""
    while [ "$VAL" == ""  ]
    do
        str1=`gettext install "Provide %s installation folder: "`
        str1=`printf "$str1" "$1"`
        read -e -p "$str1" backupPath
    
        if [ ! -z "${backupPath}" ]
	   then
		  if [ -d "${backupPath}" ]
	       then
                echo "${backupPath}"
			 return
	       else
			 str1=`gettext install "Folder not found: "`
			 write_and_log "$str1 ${backupPath}"
	       fi
	   else
		  str1=`gettext install "Provide valid %s folder: "`
          str1=`printf "$str1" "$1"`
		  write_and_log "$str1"
	   fi
    done
}

common_pwd()
{
	source_prompt_file
	if [ "$TREE_CONFIG" == "upgradetree" ]
	then
		return
	fi
	if [ "$UPGRADE_IDM" == "y" ]
	then
		return
	fi
	prompt "IS_COMMON_PASSWORD" - 'y/n' 
	if [[ "$IS_COMMON_PASSWORD" =~ ^[yY]$ ]]
	then
		prompt_pwd "COMMON_PASSWORD" confirm
	fi
}

prompt_file()
{
    local default_value="-"
    if [ -n "$2" ]
    then
        default_value=$2
    fi
    if [ "$CREATE_SILENT_FILE" == true ]
    then
        prompt_internal $1 $default_value "-"
    else
        prompt_internal $1 $default_value "file"
    fi
}

prompt_file_required_during_silentfile()
{
    local default_value="-"
    if [ -n "$2" ]
    then
        default_value=$2
    fi
    prompt_internal $1 $default_value "file"
}

prompt_folder()
{
    local default_value="-"
    if [ -n "$2" ]
    then
        default_value=$2
    fi
    if [ "$CREATE_SILENT_FILE" == true ]
    then
        prompt_internal $1 $default_value "-"
    else
        prompt_internal $1 $default_value "folder"
    fi
}

prompt_validnumber()
{
    local default_value="-"
    if [ -n "$2" ]
    then
        default_value=$2
    fi
    prompt_internal $1 $default_value "validnumber"
}

prompt_ndsData()
{
    local default_value="-"
    if [ -n "$2" ]
    then
        default_value=$2
    fi
    if [ "$CREATE_SILENT_FILE" == true ]
    then
        prompt_internal $1 $default_value "-"
    else
        prompt_internal $1 $default_value "ndsData"
    fi
}

#init_prompts common/conf/prompts.conf



#prompt "IDVAULT_TREENAME"
#prompt "TEST"
#echo "return value = $return_value"
#prompt "TEST"

#echo "return value = $return_value"

#echo "size = ${#prompt_ids[@]}"
#echo $return_value
