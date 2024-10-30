#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

################################################################################
# OS verification defninitions
################################################################################
SUPPORTED_OS_NAMES=("SUSE Linux Enterprise Server" "Red Hat Enterprise Linux")
SUPPORTED_OS_FILES=("/etc/os-release" "/etc/redhat-release")
#OS versions should be mentioned in ascending order only
SUPPORTED_SLES=("12.3" "12.4" "12.5" "15" "15.1")
SUPPORTED_RHEL=("7.5" "7.6" "8.0")
SUPPORTED_OS_VERSIONS=(SUPPORTED_SLES[@] SUPPORTED_RHEL[@])
SUPPORTED_OS_PLATFORMS=("SLES" "RHEL")

################################################################################
# Verify that the operating system is supported.
# in:
#       SUPPORTED_OS_NAME
#       SUPPORTED_OS_FILE
#       SUPPORTED_OS_VERSION
# out:
#       $? - 0: supported, non-zero: not supported
################################################################################
verify_os()
{
        local SUPPORTED_OS_NAME="$1"
        local SUPPORTED_OS_FILE="$2"
        eval local SUPPORTED_OS="$3"
        local SUPPORTED_OS_VERSION=( ${SUPPORTED_OS} )

        # see if the file that indicates a SUSE os is there
        if [ -e "${SUPPORTED_OS_FILE}" ]
        then
                # check for supported OS
                if grep -Eq "${SUPPORTED_OS_NAME}[[:blank:]]" "${SUPPORTED_OS_FILE}"
                then
                        local MAJOR_VERSION=
                        local PATCH_LEVEL=
                        local OS_VERSION=
                        if [[ ${SUPPORTED_OS_NAME} == *SUSE* ]]
                        then
				MAJOR_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'.' -f1)
				grep VERSION_ID /etc/os-release | cut -d'=' -f2 | grep -q "\."
				if [ $? -eq 0 ]
				then
				  PATCH_LEVEL=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'.' -f2)
				else
				  PATCH_LEVEL=0
				fi
				if [ ! -z "$MAJOR_VERSION" ] && [ $MAJOR_VERSION -ge 15 ]
				then
				  export INSTALL_GLIBC32BIT=true
				fi
                        fi

                        if [[ ${SUPPORTED_OS_NAME} == *Red* ]]
                        then
				MAJOR_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'.' -f1)
				grep VERSION_ID /etc/os-release | cut -d'=' -f2 | grep -q "\."
				if [ $? -eq 0 ]
				then
				  PATCH_LEVEL=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2 | cut -d'.' -f2)
				else
				  PATCH_LEVEL=0
				fi
                        fi
                        
                        write_log "OS Name = ${SUPPORTED_OS_NAME}" >> $log_file
                        write_log "OS MAJOR_VERSION = ${MAJOR_VERSION}" >> $log_file
                        write_log "OS PATCH_LEVEL = ${PATCH_LEVEL}" >> $log_file

                        if [[ -n "${MAJOR_VERSION}" && -n "${PATCH_LEVEL}" ]]
                        then
                                OS_VERSION="${MAJOR_VERSION}"".""${PATCH_LEVEL}"
                                write_log "OS_VERSION = ${OS_VERSION}" >> $log_file
                                #see if the version is supported
                                local COUNT=${#SUPPORTED_OS_VERSION[@]}
                                for (( j = 0 ; j < $COUNT ; j++ ))
                                do
                                        if (( $(echo ${OS_VERSION} ${SUPPORTED_OS_VERSION[j]} | awk '{ p=$1; q=$2; if (p == q) print 1; else print 0}') ))
                                        then
                                            return 0
                                        fi

                                done
                                #see if version is lower than supported version
#                                    if (( $(echo "${OS_VERSION} < ${SUPPORTED_OS_VERSION[0]}" |bc -l) ))
#                                    then
#                                            return 2
#                                    fi

                                    if (( $(echo ${OS_VERSION} ${SUPPORTED_OS_VERSION[0]} | awk '{ p=$1; q=$2; if (p < q) print 1; else print 0}') ))
                                    then
                                        return 2
                                    fi
                                    if (( $(echo ${OS_VERSION} ${SUPPORTED_OS_VERSION[${COUNT}-1]} | awk '{ p=$1; q=$2; if (p > q) print 1; else print 0 }') ))
                                    then
                                        return 3
                                    fi
                                return 4
                        fi
                fi
        fi
        return 1
}

################################################################################
# Verify that the operating system is supported. If yes, set MANIFEST_FILE 
# based on OS. If not, ask the user if he wants to continue.
# out:
#       $? - 0: continue, non-zero: abort
################################################################################

verify_OSs()
{
    if [ $IS_SYSTEM_CHECK_DONE -eq 1 ]
    then
        str1=`gettext install "Installer has detected that either System check is already complete OR it should be skipped based on install parameter(s)..."`
        str2=`gettext install "Operating System: Check will not be performed."`
        write_log "$INSTR $str1 $str2"
        return
    fi
    local VERIFY=
    for (( i =0 ; i < ${#SUPPORTED_OS_NAMES[@]} ; i++ ))
    do
            verify_os "${SUPPORTED_OS_NAMES[$i]}" "${SUPPORTED_OS_FILES[$i]}" "\${!SUPPORTED_OS_VERSIONS[$i]}"
            VERIFY=$?
            if [ ${VERIFY} -eq 0 ]
            then
        str1=`gettext install "Operating system "`
        str2=`gettext install " is supported..."`
        write_log "$INSTR $str1 ${SUPPORTED_OS_NAMES[$i]} ${!SUPPORTED_OS_VERSIONS[$i]} $str2"
                    return 0
            elif [ ${VERIFY} -ne 1 ]
            then
                    break
            fi
    done
    # unsupported OS, or unsupported version
    for (( i =0 ; i < ${#SUPPORTED_OS_NAMES[@]} ; i++ ))
    do
        if [[ -f "${SUPPORTED_OS_FILES[$i]}" ]]; then
             MANIFEST_FILE="product-${SUPPORTED_OS_PLATFORMS[$i]}.manifest"
             VERIFY_OS_MANIFEST=0
        fi
    done
    str1=`gettext install "This machine does not have a certified operating system."`
    write_and_log "$INSTR $str1"
    str2=`gettext install "You are attempting to install this product on an operating system that was not certified at the time of release of this installer. Micro Focus periodically tests and certifies additional operating systems and platforms. For the latest information about certified operating systems and platforms, see the Identity Manager Technical Information Web site. (https://www.netiq.com/products/identity-manager/advanced/technical-information/).')."`
    write_and_log "$INSTR $str2"
    
    str3=`gettext install "If your operating system is not currently on the list, consider migrating or upgrading to a certified operating system. If you continue, Micro Focus will support your installation, but reported issues must be reproduced on certified platforms to be considered for resolution."`
    
    if [ $UNATTENDED_INSTALL -eq 1 ]
    then
        write_and_log "$INSTR $str1"
        write_and_log "$INSTR $str2"
        write_and_log "$INSTR $str3"
        str4=`gettext install "Refer to the install parameters in case you wish to continue installation on this platform"`
        write_and_log "$INSTR $str4"
        exit
    fi
    
    # Check if user wants to proceed.
    
    write_and_log "$INSTR $str3"
    if [ ! -n "$OS_SUPPORTED" ]
    then
      ckyornstr=`gettext install "Do you want to continue?"`
      ckyorn -p "$INSTR $ckyornstr"
    if [ $ans = "yes" ] || [ $ans = "y" ]
    then
        str1=`gettext install "Installation will be performed on an uncertified platform..."`
        write_and_log "$INSTR $str1."
        return 0
      else
            # If the user don't want to proceed.
            exit
      fi
     fi
}
