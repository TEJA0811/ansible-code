#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

MENU_OPTIONS=()
MENU_OPTIONS_DISPLAY=()
SELECTION=()
SELECTION_DISPLAY=()
MESSAGE=


txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtblu=$(tput setaf 4)    # Blue
txtpur=$(tput setaf 5)    # Purple
txtcyn=$(tput setaf 6)    # Cyan
txtwht=$(tput setaf 7)    # White
txtrst=$(tput sgr0)       # Text reset

menu() 
{
    
    for i in ${!MENU_OPTIONS_DISPLAY[@]}; do 
        printf "%3d%s) %s\n" $((i+1)) "${MENU_USER_CHOICES[i]:- }" "${MENU_OPTIONS_DISPLAY[i]}"
    done
    echo_sameline ""
}

get_selection()
{
    SELECTION=()
    SELECTION_DISPLAY=()
    if [ $IS_UPGRADE -eq 1 ] && [ -z "$IS_UNINSTALL" ]
    then
        str1=`gettext install "Specify only one component that you want to upgrade. To confirm, press Enter:"`
    elif [ "$IS_UNINSTALL" == "1" ]
    then
        str1=`gettext install "Specify the component(s) that you want to uninstall. To uninstall multiple components, specify the values as a comma-separated list [For example, 1, 2, 3]. To confirm, press Enter:"`
        str1="$str1 ${txtrst}"
    else
        str1=`gettext install "Specify the component(s) that you want to install. To install multiple components, specify the values as a comma-separated list [For example, 1, 2, 3]. To confirm, press Enter:"`
        str1="$str1 ${txtrst}"
    fi
    str4=`gettext install "Specify the component(s) that you want to configure. To configure multiple components, specify the values as a comma-separated list [For example, 1, 2, 3]. To confirm, press Enter:"`
    str4="$str4 ${txtrst}"
    str2=`gettext install "Choose ONLY ONE option. To continue, press Enter:"`
    str3=`gettext install "The selected component(s) are highlighted below. To confirm, press Enter. To deselect a component, type the value of the component that you want to deselect. "`
    if [ "$1" != "" ] && [ "$1" = "1" ] && [ "$1" != "true" ]
    then
        str=$str2
        echo_sameline ""    
    else
        str=$str1
        echo_sameline ""
    fi
    if [ "$1" = "true" ]
    then
       str=$str4
       echo_sameline ""
    fi   
       
    #str=$str3
  if [ ! -z "$promptsforRLonly" ] && [ "$promptsforRLonly" == "true" ]
  then
    while menu && num=1 && [[ "1" ]]; do
     IFS=', ' read -r -a inputs <<< "$num"
     for USER_CHOICE in "${inputs[@]}"
     do
      ((USER_CHOICE--))
      [[ "${MENU_USER_CHOICES[USER_CHOICE]}" ]] && MENU_USER_CHOICES[USER_CHOICE]="" || MENU_USER_CHOICES[USER_CHOICE]="${txtpur}+${txtrst}" && ((USER_CHOICE--))
     done
     break
    done
  else
    while menu && read -rp "$str" num && [[ "$num" ]]; do
        IFS=', ' read -r -a inputs <<< "$num"
        for USER_CHOICE in "${inputs[@]}"
        do
	    if ! [[ "$USER_CHOICE" =~ ^[0-9]+$ ]]
  	    then
               echo_sameline "${txtred}"
               str1=`gettext install "Invalid input. Enter value(s) between 1 and %s."`
               str1=`printf "$str1" "${#MENU_OPTIONS[@]}"`
               write_and_log "$str1"
               echo_sameline "${txtrst}"
               break
	    fi
	    if [[ "$USER_CHOICE" -gt ${#MENU_OPTIONS[@]} ]] || [[ "$USER_CHOICE" -lt 0 ]] || [[ "$USER_CHOICE" -eq 0 ]]
             then
               echo_sameline "${txtred}"
               str1=`gettext install "Invalid input. Enter value(s) between 1 and %s."`
               str1=`printf "$str1" "${#MENU_OPTIONS[@]}"`
               write_and_log "$str1"
               echo_sameline "${txtrst}"
               break
            fi

            if [[ "$USER_CHOICE" != *[![:digit:]]* ]] && (( USER_CHOICE > 0 && USER_CHOICE <= ${#MENU_OPTIONS[@]} ))
            then
		
                ((USER_CHOICE--))
                [[ "${MENU_USER_CHOICES[USER_CHOICE]}" ]] && MENU_USER_CHOICES[USER_CHOICE]="" || MENU_USER_CHOICES[USER_CHOICE]="${txtpur}+${txtrst}"
		
            fi
	    
        done
	echo_sameline ""
	echo_sameline " ============================================================================================================="
	echo_sameline "       $str3"
	echo_sameline " ============================================================================================================="
    done
  fi
    
    for i in ${!MENU_OPTIONS[@]}
    do 
        if [[ "${MENU_USER_CHOICES[i]}" ]]
        then
            SELECTION+=("${MENU_OPTIONS[i]}")
            SELECTION_DISPLAY+=("${MENU_OPTIONS_DISPLAY[i]}")
	fi
    done
}

get_user_input()
{
    local COUNT=0
    while [ $COUNT -lt 1 ]
    do
        echo_sameline ""
        echo_sameline "$MESSAGE"
        echo_sameline ""
        get_selection $1     
        COUNT=${#SELECTION[@]}
    done
}

#get_user_input
