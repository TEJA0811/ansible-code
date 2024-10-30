#!/bin/sh
set -x

status=`cat /root/status/FOA`
if [ $status == 0 ]
then
  cd $WORKSPACE/Linux_Regression_Suite/stage4_foa/validation/

  cd_status=$?
  if [ $cd_status -ne 0 ]
  then
    echo "In ${0} :"
	  echo "cd: '${WORKSPACE}/Linux_Regression_Suite/stage4_foa/validation/': No such directory "
    exit 1
  fi

  ansible-playbook -i inventory validation_foa.yml -e "@../../variables/global.yml" -e "@../../variables/versions.yml"

  ansible_status=$?
  if [ $ansible_status -ne 0 ]
  then
    echo "In ${0} :"
	  echo "Failed: Ansible execution for FOA validation "
  fi
else
  echo "Aborting Ansible execution for FOA validation due to failure in FOA staging "
fi