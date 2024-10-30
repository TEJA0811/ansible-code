#!/bin/sh

set -x

cd $WORKSPACE/pipeline/consolidation/

ansible-playbook -i inventory -e "results_dir=$WORKSPACE/../consolidate_reports" consolidated_mail.yml

ansible_status=$?
if [ $ansible_status -ne 0 ]
then
  echo "In ${0} :"
	echo "Failed: Ansible execution for generating consolidated mail"
fi

mv $WORKSPACE/../consolidate_reports $WORKSPACE

rm -rf /root/status