#!/bin/sh
BUILD_NUMBER=$1
set -x

cd $WORKSPACE/Linux_Regression_Suite/consolidation/

ansible-playbook -i inventory consolidated_mail.yml -e "idm_build_no=$BUILD_NUMBER" -e "@../variables/global.yml"

ansible_status=$?
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for generating consolidated mail"
fi

#mv $WORKSPACE/../consolidate_reports $WORKSPACE
cp -r /root/consolidate_reports $WORKSPACE

rm -rf /root/status