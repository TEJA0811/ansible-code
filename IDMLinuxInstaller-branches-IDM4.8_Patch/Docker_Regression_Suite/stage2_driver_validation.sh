#!/bin/sh
set -x

status=`cat /root/status/Driver`

if [ $status == 0 ]
then
  cd $WORKSPACE/pipeline/stage2_drivers/validation/

  cd_status=$?
  if [ $cd_status -ne 0 ]
  then
    echo "In ${0} :"
  	echo "cd: '${WORKSPACE}/pipeline/stage2_drivers/validation/': No such directory "
    exit 1
  fi

  ansible-playbook -i inventory -e "results_dir=$WORKSPACE/../consolidate_reports" -e "@../../variables/global.yml" -e "@../../variables/versions.yml" validation_drivers.yml

  ansible_status=$?
  if [ $ansible_status -ne 0 ]
  then
    echo "In ${0} :"
	  echo "Failed: Ansible execution for driver validation "
  fi
else
  echo "Aborting Ansible execution for Driver validation due to failure in Driver staging "
fi
