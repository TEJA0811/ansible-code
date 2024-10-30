#!/bin/sh
set -x

status_file='/root/status/IDC'
touch $status_file
> $status_file

cd $WORKSPACE/Linux_Regression_Suite/stage5_idconsole/staging/

cd_status=$?
if [ $cd_status -ne 0 ]
then
  echo "In ${0} :"
	echo "'${WORKSPACE}/Linux_Regression_Suite/stage5_idconsole/staging/' : no such directory "
  exit 1
fi

ansible-playbook -i inventory staging_IDC.yml -e "@../../variables/global.yml"

ansible_status=$?
echo $ansible_status > $status_file
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for IDConsole staging"
  TEST_IDC=1
fi