#!/bin/sh
set -x

status=0

if [ $status == 0 ]
then
  cd $WORKSPACE/pipeline/stage3_rl/validation/

  cd_status=$?
  if [ $cd_status -ne 0 ]
  then
    echo "In ${0} :"
  	echo "cd: '${WORKSPACE}/pipeline/stage3_rl/validation/': No such directory "
    exit 1
  fi

  ansible-playbook -i inventory -e "results_dir=$WORKSPACE/../consolidate_reports" -e "@../../variables/global.yml" -e "@../../variables/versions.yml" validation_rl.yml

  ansible_status=$?
  if [ $ansible_status -ne 0 ]
  then
    echo "In ${0} :"
	  echo "Failed: Ansible execution for Remote loader validation "
  fi
else
  echo "Aborting Ansible execution for RL validation due to failure in RL staging "
fi