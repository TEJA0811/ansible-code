#!/bin/sh
set -x

status_file='/root/status/Engine'
touch $status_file
> $status_file

cd $WORKSPACE/pipeline/stage1_engine/staging/

cd_status=$?
if [ $cd_status -ne 0 ]
then
  echo "In ${0} :"
	echo "'${WORKSPACE}/pipeline/stage1_engine/staging/' : no such directory "
  exit 1
fi

ansible-playbook -i inventory staging_engine.yml -e "@../../variables/global.yml"

ansible_status=$?
echo $ansible_status > $status_file
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for engine staging"
fi