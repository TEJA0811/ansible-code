#!/bin/sh
set -x

status=`cat /root/status/IDC`

if [ $status == 0 ]
then
  cd $WORKSPACE/Linux_Regression_Suite/stage5_idconsole/validation/

  cd_status=$?
  if [ $cd_status -ne 0 ]
  then
    echo "In ${0} :"
  	echo "'${WORKSPACE}/Linux_Regression_Suite/stage5_idconsole/validation/' : no such directory "
    exit 1
  fi

  ansible-playbook -i inventory validation_idconsole.yml -e "@../../variables/global.yml" -e "@../../variables/versions.yml"

  ansible_status=$?
  if [ $ansible_status -ne 0 ]
  then
    echo "In ${0} :"
	  echo "Failed: Ansible execution for IDConsole validation"
  fi
else
  echo "Aborting Ansible execution for IDC validation due to failure in IDC staging "
fi