#!/bin/sh
set -x

status=`cat /root/status/RPT`

if [ $status == 0 ]
then
  cd $WORKSPACE/pipeline/stage6_reporting/validation/

  cd_status=$?
  if [ $cd_status -ne 0 ]
  then
    echo "In ${0} :"  
  	echo "'${WORKSPACE}/pipeline/stage6_reporting/validation/' : no such directory "
    exit 1
  fi

  ansible-playbook -i inventory -e "results_dir=$WORKSPACE/../consolidate_reports" -e "@../../variables/global.yml" -e "@../../variables/versions.yml" validation_reporting.yml

  ansible_status=$?
  if [ $ansible_status -ne 0 ]
  then
    echo "In ${0} :"
  	echo "Failed: Ansible execution for reporting validation"
  fi
else
  echo "Aborting Ansible execution for Reporting validation due to failure in Reporting staging "
fi