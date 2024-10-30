#!/bin/sh
set -x

status_file='/root/status/RL'
touch $status_file
> $status_file

cd $WORKSPACE/Linux_Regression_Suite/stage3_rl/staging/

cd_status=$?
if [ $cd_status -ne 0 ]
then
  echo "In ${0} :"
	echo "'${WORKSPACE}/Linux_Regression_Suite/stage3_rl/staging/' : no such directory "
  exit 1
fi

ansible-playbook -i inventory staging_rl.yml -e "@../../variables/global.yml"

ansible_status=$?
echo $ansible_status > $status_file
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for rl staging"
  TEST_RL=1
fi