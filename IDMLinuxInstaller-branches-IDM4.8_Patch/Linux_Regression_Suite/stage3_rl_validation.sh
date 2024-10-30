#!/bin/sh
set -x

status=0

if [ $status == 0 ]
then
  cd $WORKSPACE/Linux_Regression_Suite/stage3_rl/validation/

  cd_status=$?
  if [ $cd_status -ne 0 ]
  then
    echo "In ${0} :"
  	echo "cd: '${WORKSPACE}/Linux_Regression_Suite/stage3_rl/validation/': No such directory "
    exit 1
  fi

  ansible-playbook -i inventory validation_rl.yml -e "@../../variables/global.yml" -e "@../../variables/versions.yml"

  ansible_status=$?
  if [ $ansible_status -ne 0 ]
  then
    echo "In ${0} :"
	  echo "Failed: Ansible execution for Remote loader validation "
  fi
else
  echo "Aborting Ansible execution for RL validation due to failure in RL staging "
fi