#!/bin/sh
set -x

status_file='/root/status/RPT'
touch $status_file
> $status_file

cd $WORKSPACE/Linux_Regression_Suite/stage6_reporting/staging/

cd_status=$?
if [ $cd_status -ne 0 ]
then
  echo "In ${0} :"
	echo "'${WORKSPACE}/Linux_Regression_Suite/stage6_reporting/staging/' : no such directory "
  exit 1
fi

ansible-playbook staging_reporting.yml -i inventory -vv -e "@../../variables/global.yml"
# ansible-playbook -i inventory staging_reporting.yml

ansible_status=$?
echo $ansible_status > $status_file
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for reporting staging"
  TEST_RPT=1
fi