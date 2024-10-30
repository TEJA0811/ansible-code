#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

copyDirectory()
{
	if [ -f ${1} -o -d {1} ] && [ -d ${2} ]
	then
		directory=`echo "$1" | rev | cut -d"/" -f1 | rev`
		day=`date +"%m-%d-%Y"`
		time=`date +"%T"`
		cp -rpf "${1}" "${2}/${directory}_${day}_${time}"
	fi
}

