#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

txtund=$(tput sgr 0 1)    # Underline
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtblu=$(tput setaf 4)    # Blue
txtpur=$(tput setaf 5)    # Purple
txtcyn=$(tput setaf 6)    # Cyan
txtrst=$(tput sgr0)
current_version=4.8

display_copyrights()
{
    if [ $IS_LICENSE_CHECK_DONE -eq 1 ]
    then
        echo_sameline "${txtgrn}"
        write_log "License agreement has already been accepted... skipping..."
        echo_sameline "${txtrst}"
        return 0
    fi
    #write_log "Inside display copyright"
    #write_log "###############################################################"

    if [ $UNATTENDED_INSTALL -ne 1 ]
    then
#        clear
        write_and_log ""
    else
        return 0;
    fi

    lc_all=`/usr/bin/locale | grep "LC_ALL" | awk -F"=" '{print $2}'`
    if [ -z "$lc_all" ]
    then
        lang=`locale | grep "LANG" | awk -F"=" '{print $2}'`
        if [  -n "$lang" ]; then
                lang_license=`echo $lang | awk -F "_" '{print $1}'`
        fi
        if [ -n "$lang_license" ]
        then
                license_file=$IDM_INSTALL_HOME/common/license/$lang_license/license.txt
        fi
    else
        lc_all_license=`echo $lc_all | awk -F "_" '{print $1}'`
        if [ -n "$lc_all_license" ]
		then
				if [ "$lc_all_license" == "zh" ] && [[ $lc_all =~ .*zh_CN.* ]]
				then
					license_file=$IDM_INSTALL_HOME/common/license/zh_CN/license.txt
				elif [ "$lc_all_license" == "zh" ] && [[ $lc_all =~ .*zh_TW.* ]]
                then
					license_file=$IDM_INSTALL_HOME/common/license/zh_TW/license.txt
				else
					license_file=$IDM_INSTALL_HOME/common/license/$lc_all_license/license.txt
				fi
        fi
    fi
	
    if [  -r $license_file ]
    then
        write_and_log ""
    else
        license_file=$IDM_INSTALL_HOME/common/license/en/license.txt
    fi

    if [ -r $license_file ]
    then
        str1=`gettext install "Welcome to the installation of Identity Manager"`
        write_and_log "$str1."
        str1=`gettext install "for"`
        str2=`gettext install "The End User License Agreement"`
        str3=`gettext install "will now be displayed."`
        write_and_log "$str2 $str1 Identity Manager $CURRENT_IDM_VERSION $str3"
        str1=`gettext install "Read the agreement carefully before accepting the terms."`
        write_and_log  "$str1"
        str1=`gettext install "Press ENTER to continue."`
        echo_sameline "${txtylw}"
        write_and_log "$str1"
        echo_sameline "${txtrst}"
        read resp

        write_and_log ""
        echo_sameline "${txtblu}"
        more $license_file
        write_and_log ""
	    echo_sameline "${txtrst}"
        ckyornstr=`gettext install "Do you accept the terms of Identity Manager %current_version% license agreement"`
        echostr=`echo $ckyornstr | sed "s/%current_version%/$current_version/g"`
        echo_sameline "${txtylw}"
        ckyorn -p "$echostr"
        echo_sameline "${txttxt}"
        if [ $ans = "no" ] || [ $ans = "n" ]
        then
            str1=`gettext install "Cannot proceed without acceptance of License Agreement."`
            echo_sameline "${txtred}"
            write_and_log "$str1"
            write_final_log "$failure_errcode $str1"
            echo_sameline "${txtrst}"
            exit 1
        fi
    else
        str1=`gettext install "License agreement file"`
        str2=`gettext install "is missing."`
        write_and_log "$str1 $license_file $str2"
        str1=`gettext install "Aborting installation..."`
        write_and_log "$str1"
        write_final_log "$failure_errcode $str1"
        exit 1
    fi
	return 0
}

