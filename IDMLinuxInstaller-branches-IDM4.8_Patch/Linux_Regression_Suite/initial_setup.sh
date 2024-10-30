#!/bin/sh

set -x

mkdir /root/status
cd $WORKSPACE/Linux_Regression_Suite/initial_setup/

ansible-playbook initial_setup.yml -i inventory -e "@../variables/global.yml"

ansible_status=$?
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for Initial setup"
fi