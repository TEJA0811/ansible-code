#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

RPM_INSTALL_FAIL=
RPM_UPGRADE_FAIL=

txtred=$(tput setaf 1)
txtylw=$(tput setaf 3)
txtrst=$(tput sgr0)
txtcyn=$(tput setaf 6)
txtbld=$(tput bold)

Check_install()
{ 
     echo_sameline "${txtred}"
	 str1=`gettext install "Installation failed. Check /var/opt/netiq/idm/log/idminstall.log for more details."`
	 write_and_log "$str1"
	 check_errs 1 "$1"/"$2"
	 str2=`gettext install`
	 write_and_log "$str2"
     #echo "plz check $1/$2 for more details"
     #export RPM_INSTALL_FAIL=99
	 echo_sameline "${txtrst}"
	 
}


################## Common Utility For Error_Handling #######################

check_errs()
{

        
    if [ "${1}" -ne "0" ]
    then
     if [ $(echo $2 | grep "rpm$" | wc -l) -eq 1 ]
     then
        str1=`gettext install "Package installation failed for: %s"`
        str1=`printf "$str1" "$2"`
     else
       str1=`gettext install "ERROR # %s : %s "`
       str1=`printf "$str1" "$1" "$2"`
     fi
	   write_log "$str1"
	 if [ -f /var/opt/netiq/idm/log/idminstalltemp.log ]
	 then
		cat /var/opt/netiq/idm/log/idminstalltemp.log >> /var/opt/netiq/idm/log/idminstall.log
		rm /var/opt/netiq/idm/log/idminstalltemp.log
	 fi
       exit ${1}
    fi
}

check_return_value()
{
	if [ "${1}" -ne "0" ]
    then
	  echo_sameline "${txtred}"
	  str1=`gettext install "Check ${LOG_FILE_NAME} file for more information."`
	  write_and_log "$str1"
      echo_sameline "${txtrst}"
	  exit ${1}
	fi
}

########################################################################

check_conf()
{
  if [ $1 -ne 0 ]
  then
    echo_sameline $2
    echo_sameline "${txtred}"
    str1=`gettext install "Check ${LOG_FILE_NAME} file for more information."`
    write_and_log "$str1"
    echo_sameline "${txtrst}"
  fi  

}

