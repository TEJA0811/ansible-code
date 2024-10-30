#!/bin/sh

set -x

mkdir /root/status
cd $WORKSPACE/pipeline/initial_setup/

ansible-playbook initial_setup.yml -i inventory -e "results_dir=$WORKSPACE/../consolidate_reports"

ansible_status=$?
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for Initial setup"
fi