#!/bin/bash
#set -x
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
KEY=
VALUE=
#IDM_TEMP=/tmp/idm_install
TMP_FILE=${IDM_TEMP}/config-tmp.txt
###################################
# Merge the property files
###################################
merge_osp_customization_cfg_props()
{
    source=$1
    target=$2

    echo "MERGING ismconfiguration.properties. SOURCE = ${source}, TARGET = ${target}"
    echo "" > ${TMP_FILE}
    blank=`tail -1 ${source}`
    if [ ! -z "${blank}" ]
    then 
        echo -e "\n" >> "${source}"
    fi
    while read line
	do
        #echo "PROCESSING : $line"
        init_keyVal "${line}"
        #echo "KEY : ${KEY}"
        #echo "VALUE : ${VALUE}"
        if [ ! -z "${KEY}" ]
        then
            line="$(echo $line | sed -e 's#\\#\\\\#g')"
            match=`grep "${KEY}=" ${target}`
            result=$?
            if [ ${result} -ne 0 ]
            then
                match=`grep "${KEY} =" ${target}`
                result=$?
            fi
            #echo "Source Key = ${KEY}"
            if [ ${result} -eq 0 ]
            then
                #echo "REPLACING ENTRY : \"${match}\" WITH \"${line}\""
                #sed -i "s~${match}~${line}~g" ${target}
                search_and_replace "${match}" "${line}" "${target}"
            else
                #echo "ADDING ENTRY : \"${line}\""
                echo "${line}" >> ${TMP_FILE}
                #echo "${line}" >> ${target}
            fi
        else
            echo "SKIPPING..."
        fi
	done < "${source}"
    count=`wc -l ${TMP_FILE} | cut -d ' ' -f 1 | xargs`
    if [ ${count} -gt 1 ]
    then
        cat ${TMP_FILE} >> ${target}
    fi
    echo "COMPLETED MERGE..."
}

#####################################
# Split the line into key/value
#####################################
init_keyVal()
{
    KEY=
    VALUE=
    DELIM="="
    input="$1"
    if [[ ${input} == \#* ]]
    then
        echo "SKIPPING COMMENT..."
        return
    fi
    IFS=${DELIM} read -ra PROP <<< "${input}"
    for i in "${PROP[@]}"; do
        if [ "${KEY}" == "" ]
        then
            KEY="`echo ${i} | xargs`"
        else
            if [ "${VALUE}" == "" ]
            then
                VALUE="`echo ${i} | xargs -0`"
            else
                VALUE="`echo ${VALUE}${DELIM}${i} | xargs -0`"
            fi
        fi
    done
}

#Usage : merge_ism_props "<Source file>" "<Target file>"
