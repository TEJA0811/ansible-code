#!/bin/sh
set -x

status_file='/root/status/RPT'
touch $status_file
> $status_file

cd $WORKSPACE/pipeline/stage6_reporting/staging/

cd_status=$?
if [ $cd_status -ne 0 ]
then
  echo "In ${0} :"
	echo "'${WORKSPACE}/pipeline/stage6_reporting/staging/' : no such directory "
  exit 1
fi

ansible-playbook -i inventory staging_reporting.yml -e "@../../variables/global.yml"

ansible_status=$?
echo $ansible_status > $status_file
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for reporting staging"
  TEST_RPT=1
fi