#!/bin/sh
set -x

status_file='/root/status/Driver'
touch $status_file
> $status_file

cd $WORKSPACE/Linux_Regression_Suite/stage2_drivers/staging/

cd_status=$?
if [ $cd_status -ne 0 ]
then
  echo "In ${0} :"
	echo "'${WORKSPACE}/Linux_Regression_Suite/stage2_drivers/staging/' : no such directory "
  exit 1
fi

ansible-playbook -i inventory staging_drivers.yml -e "@../../variables/global.yml"

ansible_status=$?
echo $ansible_status > $status_file
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for driver staging"

fi
