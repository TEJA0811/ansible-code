#!/bin/bash
#set -x
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
. ../common/scripts/config_utils.sh
. ../common/scripts/osp_custom_cfg_util.sh
. ../common/conf/global_paths.sh

ZIP=/usr/bin/zip
UNZIP=/usr/bin/unzip

###############################
# merge the OSP jars
# $1 = source
# $2 = dest
###############################
merge_jars()
{
    SRC_OSP_JAR="$1"
    DEST_OSP_JAR="$2"

    if [ -z "${SRC_OSP_JAR}" ] || [ -z "${DEST_OSP_JAR}" ]
    then
        echo "merge_jar : Missing source/destination jar files"
        return;
    fi

    local CWD=`pwd`

    do_merge

    cd "${CWD}"
}

do_merge()
{
    local BASE="${IDM_TEMP}/osp"
    local src="${BASE}/src"
    local dest="${BASE}/dest"
    local rsrc="/resources"
    
    mkdir -p ${BASE}
    mkdir -p ${src}
    mkdir -p ${dest}

    ${UNZIP} ${SRC_OSP_JAR} -d ${src}
    ${UNZIP} ${DEST_OSP_JAR} -d ${dest}

    for file in `ls ${src}${rsrc}/*.properties`
    do
        IFS='/'
        for comp in $file
        do 
            fname=${comp}
        done
        IFS=
        dfile=${dest}${rsrc}/${fname}
        echo "====================================================="
        echo "Merging file : ${file} to ${dfile}"
        echo "====================================================="
        #merge_ism_props "${file}" "${dfile}"
        merge_osp_customization_cfg_props "${file}" "${dfile}"
        echo "====================================================="
    done

    # copy the images, css and jsp files
    yes | cp -pf ${src}/images/* ${dest}/images/ &> /dev/null
    yes | cp -pf ${src}/jsp/* ${dest}/jsp/ &> /dev/null
    yes | cp -pf ${src}/css/* ${dest}/css/ &> /dev/null

    # backup the existing destination file
    mv "${DEST_OSP_JAR}" "${DEST_OSP_JAR}.orig"
    cd ${dest}
    
    ${ZIP} -r -0 ${DEST_OSP_JAR} *

    chmod +x ${DEST_OSP_JAR}

    # Clean up the files
    rm -r ${BASE}
}

#Usage
#merge_jars <source jar> <dest jar>
