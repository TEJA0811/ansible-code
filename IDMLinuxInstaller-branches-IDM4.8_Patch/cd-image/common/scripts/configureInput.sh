#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

duplStatus=
answer=""
VARVALUEFROMSEARCH=
IDMCONF=/etc/opt/netiq/idm/conf/idmconf.properties
MASTERCONFFILE=/etc/opt/netiq/idm/conf/idmprompt.properties
PASSCONF=/etc/opt/netiq/idm/conf/.pass

getVariableValue()
{
	if [ -f "${IDMCONF}" ]
	then
		VARTOSEARCH=$1
		VARVALUEFROMSEARCH=
		while read line
		do
			IFS="=" read -ra VARNAMEVALUE <<< "$line"
			
			if [ "${VARNAMEVALUE[0]}" == "$VARTOSEARCH" ]
			then
				VARVALUEFROMSEARCH=${VARNAMEVALUE[1]}
				if [ "${VARNAMEVALUE[2]}" != "" ]
				then
					i=2
					while [ "${VARNAMEVALUE[i]}" != "" ]
					do
						VARVALUEFROMSEARCH="${VARVALUEFROMSEARCH}=${VARNAMEVALUE[i]}"
						i=`expr $i + 1`
					done
				fi
				return 
			fi

		done < "$IDMCONF"	
	else
        write_log "${IDMCONF} is not available."
	fi
}

setVariableValue()
{
	if [ -f "${IDMCONF}" ]
	then
		VARTOSEARCH=$1
		VALTOREPLACE=$2
		while read line
		do
			IFS="=" read -ra VARNAMEVALUE <<< "$line"
		
			if [ "${VARNAMEVALUE[0]}" == "$VARTOSEARCH" ]
			then
				NEW_STRING="${VARNAMEVALUE[0]}=${VALTOREPLACE}"
				sed -i "/${line}/c ${NEW_STRING}" "$IDMCONF"
				return 
			fi

		done < "$IDMCONF"	
	else
        write_log "${IDMCONF} is not available."
	fi
}

## Finds duplicate entry of input configuration
findDuplicateVars()
{
	duplVarName=$1
	duplFileToSearch=$2
	duplStatus="false"
	if [ -f "$duplFileToSearch" ]
	then
		while read confinputDup
		do
			IFS="|" read -ra VARNAMESDUP <<< "$confinputDup"

			if [ "${VARNAMESDUP[0]}" == "$duplVarName" ]
			then
				duplStatus="true"
			fi

		done < "$duplFileToSearch"
	fi
}

## Creates unique configuration file for obtaining inputs from users
readAndCreateUniqueVars()
{
    if [ ${SKIP_PROMPTS} -eq 1 ]
    then
        write_log "User prompts have already been answered ... skipping readAndCreateUniqueVars."
        return
    fi
	inputVarFile=$1
	if [ "${2}" != "" ]
	then
		inputVarFile="${2}/${inputVarFile}"
	fi

	MASTERCONFDIR=`dirname ${MASTERCONFFILE}`
	if [ ! -d "${MASTERCONFDIR}" ]
	then
		mkdir -p "${MASTERCONFDIR}"
	fi

	while read confinput
	do
		IFS="|" read -ra VARNAMES <<< "$confinput"
	
		findDuplicateVars "${VARNAMES[0]}" "$MASTERCONFFILE"

		if [ "$duplStatus" == "false" ]
		then
			if [ "${VARNAMES[4]}" != "" ]
			then
				echo "${VARNAMES[0]}|${VARNAMES[1]}|${VARNAMES[2]}|${VARNAMES[3]}|"$2/${VARNAMES[4]}"|${VARNAMES[5]}" >> "$MASTERCONFFILE"
			else
				echo "$confinput" >> "$MASTERCONFFILE"
			fi
		fi
	done < "$inputVarFile"
}

## To obtain extended input for configuration selected by user
extendedUserInput()
{
	extendedUserInputConf="$1"

	while read confInputLine
	do
		IFS="|" read -ra EXTVARNAMES <<< "$confInputLine"
		echo "${EXTVARNAMES[0]}=${EXTVARNAMES[3]}" >> $IDMCONF
	done < "$extendedUserInputConf"
}

config_mode()
{

    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        write_log "Silent mode detected... skipping config_mode."
        return
    fi

    if [ ${SKIP_PROMPTS} -eq 1 ]
    then
        write_log "User prompts have already been answered ... skipping config_mode."
        return
    fi

    if [ ! -z "$IS_ADVANCED_MODE" ]
    then
    	return
    fi
    
	update_config_list
	
	k=${#MENU_OPTIONS[@]}
	if [ $k -eq 0 ]
    then
		MENU_OPTIONS=()
		MENU_OPTIONS_DISPLAY=()
	    return
    fi
	
    typicalSTRING=`gettext install "Typical Configuration"`
    customSTRING=`gettext install "Custom Configuration"`
    
    OPT=true
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

## User Input for the configuration of products selected by user
userInput()
{
    if [ ${SKIP_PROMPTS} -eq 1 ]
    then
        write_log "User prompts have already been answered ... skipping userInput."
        return
    fi
    
    if [ -f $MASTERCONFFILE ]
    then
	while read confinputDup
	do
		IFS="|" read -ra VARNAMESDUP <<< "$confinputDup"

		varManProperty=${VARNAMESDUP[1]}
		varType=$1

		reqUserInput="false"
		if [ "${varType,,}" == "advanced" ]
		then
			if [ "${varManProperty,,}" == "optional" -o "${varManProperty,,}" == "mandatory"  -o "${varManProperty,,}" == "password_prompt" -o "${varManProperty,,}" == "password_noprompt" ]
			then
				reqUserInput="true"
			fi
		else
			if [ "${varManProperty,,}" == "mandatory"  -o "${varManProperty,,}" == "password_prompt" ]
			then
				reqUserInput="true"
			fi
		fi

		if [ "$reqUserInput" == "true" ]
		then
			answer=""
			str=`gettext install "${VARNAMESDUP[2]}"`
			if [ -n "${VARNAMESDUP[3]}" ]
			then
				echo -n "$str [ ${VARNAMESDUP[3]} ] : "
			else
				echo -n "$str : "
			fi
			
			if [ "${varManProperty,,}" == "password_prompt" -o "${varManProperty,,}" == "password_noprompt" ]
			then
				read -s answer </dev/tty
                echo ""
				CONFDIR=`dirname ${IDMCONF}`
				if [ "$answer" = "" ]
				then
					echo "export ${VARNAMESDUP[0]}=${VARNAMESDUP[3]}" >> "${PASSCONF}"
				else
					echo "export ${VARNAMESDUP[0]}=$answer" >> "${PASSCONF}"
				fi		
			else
				read answer </dev/tty
				if [ -n "${VARNAMESDUP[4]}"  ]
				then
					if [ "$answer" = "" -o "$answer" == "${VARNAMESDUP[5]}" ]
					then
						echo "${VARNAMESDUP[0]}=${VARNAMESDUP[3]}" >> $IDMCONF
						extendedUserInput "${VARNAMESDUP[4]}"
					else
						echo "${VARNAMESDUP[0]}=$answer" >> $IDMCONF
					fi
				else
					if [ "$answer" = "" ]
					then
						echo "${VARNAMESDUP[0]}=${VARNAMESDUP[3]}" >> $IDMCONF
					else
						echo "${VARNAMESDUP[0]}=$answer" >> $IDMCONF
					fi		
				fi
			fi
		elif [ "${varManProperty,,}" == "noprompt" -o "${varManProperty,,}" == "optional" -o "${varManProperty,,}" == "password_noprompt" ]
		then
			echo "${VARNAMESDUP[0]}=${VARNAMESDUP[3]}" >> $IDMCONF
		fi

	done < "$MASTERCONFFILE"
    fi
}

## Below test code to be removed before end of release
#main()
#{
#	> $MASTERCONFFILE
#	> $IDMCONF
#	readAndCreateUniqueVars sampleconf.properties
#	readAndCreateUniqueVars sampleconf1.properties
#	userInput "custom"
#	getVariableValue "IDVAULT_TREENAME"
#	if [ -n "$VARVALUEFROMSEARCH" ]
#	then
#		echo "Found Variable value for IDVAULT_TREENAME : ${VARVALUEFROMSEARCH}"
#	fi
#}

#main

