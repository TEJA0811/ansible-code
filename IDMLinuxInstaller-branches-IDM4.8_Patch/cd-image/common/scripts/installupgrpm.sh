#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
. ../common/scripts/prompts.sh &> /dev/null
. ../common/conf/global_paths.sh &> /dev/null
. common/scripts/prompts.sh &> /dev/null
. common/conf/global_paths.sh &> /dev/null
userid=`id -u`

#-----------------------------------------------------------
# exit the program, after throwing error message to the console, 
#       and to the log_file is provided
#-----------------------------------------------------------
exit_installer()
{
        local error_msg=$1
        local log_file_path="$2"
        if [ -z "${log_file_path}" -o ! -f  "${log_file_path}" ]
        then
                log_file_path="/dev/null"
                #But check if the first paramter assumed to be msg, is log file
                if [ ! -z "${error_msg}" -a -f "${error_msg}" ]
                then
                        log_file_path=$1
                        error_msg=""
                fi
        fi

        echo |  tee -a ${log_file_path}
        echo ${error_msg} | tee -a ${log_file_path}
        echo ${MSG_TERMINATE_INSTALLER} | tee -a ${log_file_path}
        echo |  tee -a ${log_file_path}
        if [ -z "${ORIG_DIR}" ]
        then
                cd "${ORIG_DIR}" >> ${log_file_path}
        fi
        exit 1
}




#-----------------Install the given rpm, from given directory and log to give log file
install_rpm()
{
        local install_msg="$1"
        local rpm_name="$2"
        local rpm_path="$3"
        local log_file_path="$4"
        local rpm_options="$5"
        if [ -z "${log_file_path}" ]
        then    
                log_file_path="/dev/null"
        fi

        echo >> "${log_file_path}"
        str1=`gettext install "Installing %s"`
        str1=`printf "$str1" "${install_msg}"`

        write_and_log "$str1"

        if [ -z "${rpm_path}" ]
        then
                str1=`gettext install "Failed"`
                echo -n "${str1}" | tee -a  "${log_file_path}"
                str1=`gettext install "rpm path $rpm_path is not valid"`
                exit_installer "${str1}" "${log_file_path}"
        fi

        if [ -z "${rpm_name}" ]
        then
                str1=`gettext install "Failed"`
                echo -n "${str1}" | tee -a  "${log_file_path}"
                str1=`gettext install "rpm name $rpm_name is not valid"`
                exit_installer "${str1}" "${log_file_path}"
        fi

        rpm -ihv --hash ${rpm_options} "${rpm_path}/${rpm_name}" >> ${log_file_path} 2>&1
        RC=$?
        if [ $RC -ne 0 ]
        then
                str1=`gettext install "Already installed, upgrading..."`
                echo "${str1}" >>  "${log_file_path}"
                rpm -Uhv --hash "${rpm_path}/${rpm_name}" >> ${log_file_path} 2>&1
                if [ $? -ne 0 ]
                then
                        str1=`gettext install "Failed"`
                        echo -n "${str1}" | tee -a  "${log_file_path}"
                        str1=`gettext install "Error while installing %s. Check the %s log file for more information."`
                        str1=`printf "$str1" "$install_msg" "${log_file_path}"`
                        exit_installer "${str1}"
                fi
        fi

#        echo ${rc_done} 
        echo >> "${log_file_path}"
}





LinuxinstallPkg()
{
    path=$1
    pkg=$2
    pkgname=$3
    if [ "$pkgname" == "novell-AUDTplatformagent" ]
    then
    	if [ $userid -ne 0 ]
	then
		return
	fi
    fi
    if [ -z "${pkgname}" ]
    then
    	return
    fi
    i_pkg=`rpm -q ${pkgname}`
    #echo "path=${path}, pkg=${pkg}, pkgname=${pkgname}, i_pkg=${i_pkg}"
    #write_and_log "$INSTR"
    INSTALL=0
    source_prompt_file
    if [ ! -z $DEDUCED_NONROOT_IDVAULT_LOCATION ]
    then
    	NONROOT_IDVAULT_LOCATION=$DEDUCED_NONROOT_IDVAULT_LOCATION
    fi
    echo $i_pkg |grep "is not installed" >> /dev/null
    if [ $? -eq 0 ]
    then
        INSTALL=1
    else
        ARCH=`echo ${i_pkg} | cut -d '-' -f 4 | cut -d '.' -f 2`
        echo $pkg | grep ${ARCH} &> /dev/null
        if [ $? -ne 0 ]
        then
            INSTALL=0
        fi
    fi
    
    if [ $INSTALL -eq 1 ] || [ ! -z "$NONROOT_IDVAULT_LOCATION" ]
    then
    	if [ ! -z "$NONROOT_IDVAULT_LOCATION" ]
	then
		ROOTDIRTEMP=$NONROOT_IDVAULT_LOCATION/../../../
		ROOTDIR=$(readlink -m "$ROOTDIRTEMP")
		RPMDBTEMP=$ROOTDIR/rpm
		RPMDB=$(readlink -m "$RPMDBTEMP")
		if [ ! -f $RPMDB/__db.000 ]
		then
			mkdir -p $RPMDB
			rpm  --dbpath "$RPMDB" --initdb
		fi
		EDIR_LOC=$NONROOT_IDVAULT_LOCATION
		if [ -f "${EDIR_LOC}/lib64/nds-modules/jre/lib/security/cacerts" ]
		then
			cp      ${EDIR_LOC}/lib64/nds-modules/jre/lib/security/cacerts /tmp/cacerts.64.nonroot
		fi
	fi
        str1=`gettext install "Installing %s"`
        str1=`printf "$str1" "$pkg"`
	write_log "$str1"
	obsoletesrpmname=`rpm -qp --obsoletes ${path}/${pkg} 2>> ${log_file}` >> ${log_file}  2>&1
	if [ "$obsoletesrpmname" != "" ] || [ ! -z "$NONROOT_IDVAULT_LOCATION" ]
	then
		if [ -z "$NONROOT_IDVAULT_LOCATION" ]
		then
			if [ "$pkgname" == "netiq-jre" ] || [ "$pkgname" == "netiq-jrex" ]
			then
				if [ -z "$RPMFORCE" ]
				then
					RPMFORCE="--force"
					unsetrpmforce="true"
				fi
			fi
			if [ "$pkgname" == "netiq-tomcat" ]
			then
				rpm -e --noscripts "netiq-tomcat-8.5.27-0.noarch" &> /dev/null
			fi
			if [ "$pkgname" == "netiq-idmtomcat" ]
			then
			    TOMCAT_SERVICE="netiq-tomcat.service"
			    if [ $(systemctl is-active $TOMCAT_SERVICE) == "active" ]
                then
                    systemctl stop $TOMCAT_SERVICE  >> /dev/null
                    #service $TOMCAT_SERVICE stop >> /dev/null
                fi
                ACTIVEMQ_SERVICE="netiq-activemq.service"
			    if [ $(systemctl is-active $ACTIVEMQ_SERVICE) == "active" ]
                then
                    systemctl stop $ACTIVEMQ_SERVICE  >> /dev/null
                fi
				rpm -e --noscripts "netiq-idmtomcat-8.5.27-0.noarch" &> /dev/null
			fi
			if [ "$pkgname" == "netiq-activemq" ]
			then
			    ACTIVEMQ_SERVICE="netiq-activemq.service"
			    if [ $(systemctl is-active $ACTIVEMQ_SERVICE) == "active" ]
                then
                    systemctl stop $ACTIVEMQ_SERVICE  >> /dev/null
                    #service $TOMCAT_SERVICE stop >> /dev/null
                fi
				rpm -e --noscripts "netiq-activemq-5.15.2-0.noarch" &> /dev/null
			fi
			rpm -Uvh --hash $NOSCRIPTS $RPMFORCE $NODEPS ${path}/${pkg} >> ${log_file}  2>&1
			RC=$?
		else
			RPM_FLAGS="--dbpath $RPMDB -Uvh --relocate=/usr=${EDIR_LOC} --relocate=/etc=$ROOTDIR/etc --relocate=/opt/novell/naudit=${EDIR_LOC}/../naudit/ --relocate=/opt/novell/eDirectory=${EDIR_LOC} --relocate=/opt/novell/dirxml=$ROOTDIR/opt/novell/dirxml --relocate=/var=$ROOTDIR/var --relocate=/opt/netiq/common/i686=$ROOTDIR/opt/netiq/common/i686 --relocate=/opt/netiq/common=$ROOTDIR/opt/netiq/common --badreloc --nodeps --replacefiles"
			rpm  $RPM_FLAGS ${path}/${pkg} >> ${log_file}  2>&1
			RC=0
		fi
		if [ ! -z "$unsetrpmforce" ] && [ "$unsetrpmforce" == "true" ]
		then
			RPMFORCE=""
		fi
	else
		rpm -ivh --hash $NOSCRIPTS $RPMFORCE $NODEPS ${path}/${pkg} >> ${log_file}  2>&1
		RC=$?
		if [ $RC -eq 1 ]
		then
			RC=0
		fi
	fi
	if [ $RC -ne 0 ]
	then
	 Check_install ${path} ${pkg}
	 exit 1
	 fi
    elif [ "${i_pkg}.rpm" = "${pkg}" ]
    then
        str1=`gettext install "Package %s is already installed... skipping."`
        str1=`printf "$str1" "$i_pkg"`
	write_and_log "$INSTR $str1"
    else
        #TODO : Check the version before performing the upgrade...
        str1=`gettext install "Upgrading Package %s to %s."`
        str1=`printf "$str1" "$i_pkg" "${pkg}"`
	write_log "$INSTR $str1"
	if [ "$pkgname" == "netiq-jre" ] || [ "$pkgname" == "netiq-jrex" ]
	then
		if [ -z "$RPMFORCE" ]
		then
			RPMFORCE="--force"
			unsetrpmforce="true"
		fi
	fi
	if [ "$pkgname" == "netiq-tomcat" ]
	then
		rpm -e --noscripts "netiq-tomcat-8.5.27-0.noarch" &> /dev/null
	fi
	if [ "$pkgname" == "netiq-idmtomcat" ]
	then
	    TOMCAT_SERVICE="netiq-tomcat.service"
		if [ $(systemctl is-active $TOMCAT_SERVICE) == "active" ]
        then
            systemctl stop $TOMCAT_SERVICE  >> /dev/null
            #service $TOMCAT_SERVICE stop >> /dev/null
        fi
        ACTIVEMQ_SERVICE="netiq-activemq.service"
	    if [ $(systemctl is-active $ACTIVEMQ_SERVICE) == "active" ]
        then
            systemctl stop $ACTIVEMQ_SERVICE  >> /dev/null
        fi
		rpm -e --noscripts "netiq-idmtomcat-8.5.27-0.noarch" &> /dev/null
	fi
	if [ "$pkgname" == "netiq-activemq" ]
    then
	    ACTIVEMQ_SERVICE="netiq-activemq.service"
	    if [ $(systemctl is-active $ACTIVEMQ_SERVICE) == "active" ]
        then
            systemctl stop $ACTIVEMQ_SERVICE  >> /dev/null
            #service $TOMCAT_SERVICE stop >> /dev/null
        fi
		    rpm -e --noscripts "netiq-activemq-5.15.2-0.noarch" &> /dev/null
	fi
        [ -f ${path}/${pkg} ] && rpm -Uvh --hash $NOSCRIPTS $RPMFORCE $NODEPS ${path}/${pkg} >> ${log_file}  2>&1
#	RC=$?
#	if [ $RC -ne 0 ]
#	then
#	Check_install ${path} ${pkg}
#	exit 1
#	fi
	if [ ! -z "$unsetrpmforce" ] && [ "$unsetrpmforce" == "true" ]
	then
		RPMFORCE=""
	fi
    fi
    
    #write_log "(install pkg)pkg=$pkg, pkgname=$pkgname "

	#if ! rpm -Uvh --hash $NOSCRIPTS --dbpath $NDSHOME/var/lib/rpm $rpmforce $pkg |  tee -a ${log_file}
	#then
	#	return 1
	#fi
}

LinuxuninstallPkg()
{
    pkgname=$1
	rpm -e $pkgname &> /dev/null
        str1=`gettext install "Removing %s ...done"`
        str1=`printf "$str1" "$pkgname"`
	[ $? == 0 ] && write_and_log "$INSTR $str1"
}


installrpm()
{
	rpmPath=$1
	rpmFile=$2

	if [ -f $rpmFile ] ; then
		cat $rpmFile | while read rpmDetails
		do
			stringarray=($rpmDetails)
			rpmPkg=${stringarray[0]}
			rpmPkgName=${stringarray[1]}
			rpmfilename=`ls $rpmPath/$rpmPkg 2> /dev/null`
			if [ -z "$rpmfilename" ] || [ "$rpmfilename" == "" ]
			then
				continue
			fi
			LinuxinstallPkg $rpmPath $rpmPkg $rpmPkgName
			if  echo "$rpmFile" | grep "deps.list" >/dev/null
			then
				if [ -f "$UNINSTALL_FILE_DIR/common.list" ] && [ $userid -eq 0 ]
				then
					if echo "$UNINSTALL_FILE_DIR/common.list" | grep "$rpmPkg" >/dev/null
					then
                                                str1=`gettext install "%s exists and not required to add in common.list"`
                                                str1=`printf "$str1" "$rpmPkg"`
						write_log "$INSTR ${str1}"
					else
						if [ ! -d "$UNINSTALL_FILE_DIR" ]
						then
							mkdir -p "$UNINSTALL_FILE_DIR"
						fi
						echo "$rpmDetails" >> "$UNINSTALL_FILE_DIR/common.list"
					fi
				fi
			fi
		done
		if [ $? -ne 0 ] 
		then
		exit 1
		fi
	else
		str1=`gettext install "doesn't exist"`
		#write_and_log "$INSTR $rpmPkg $str1"
	fi
	if [ $userid -eq 0 ]
	then
		if  echo "$rpmFile" | grep "deps.list" >/dev/null
		then
        	        str1=`gettext install "%s RPM ordering not required for common list."`
                	str1=`printf "$str1" "$rpmPkg"`
			write_log "$INSTR ${str1}"
		else
			mkdir -p $UNINSTALL_FILE_DIR/$PROD_NAME
			rpmfilebasename=$(basename $rpmFile)
			rpmfiledirname=$(dirname $rpmFile)
			rpmfiledirnamebasename=$(basename $rpmfiledirname)
			if [ "$rpmfiledirname" == "." ]
			then
			  cp -p $rpmFile $UNINSTALL_FILE_DIR/$PROD_NAME/$rpmFile
			  tac $UNINSTALL_FILE_DIR/$PROD_NAME/$rpmFile > $UNINSTALL_FILE_DIR/$PROD_NAME/tmp.list
			  mv $UNINSTALL_FILE_DIR/$PROD_NAME/tmp.list $UNINSTALL_FILE_DIR/$PROD_NAME/$rpmFile
			else
			  mkdir -p $UNINSTALL_FILE_DIR/$rpmfiledirnamebasename &> /dev/null
			  cp -p $rpmFile $UNINSTALL_FILE_DIR/$rpmfiledirnamebasename/
			  tac $rpmFile > $UNINSTALL_FILE_DIR/$rpmfiledirnamebasename/tmp.list
			  mv $UNINSTALL_FILE_DIR/$rpmfiledirnamebasename/tmp.list $UNINSTALL_FILE_DIR/$rpmfiledirnamebasename/$rpmfilebasename
			fi
		fi
	fi
}


uninstallrpm()
{
	PROD_NAME=$1
	rpmFile=$2

	if [ "$PROD_NAME" = "COMMON" ] ; then
		if [ -f $UNINSTALL_FILE_DIR/$rpmFile ] ; then
			cat $UNINSTALL_FILE_DIR/$rpmFile | while read rpmDetails
			do
				stringarray=($rpmDetails)
				rpmPkg=${stringarray[0]}
				rpmPkgName=${stringarray[1]}
				LinuxuninstallPkg $rpmPkgName
			done
			rm $UNINSTALL_FILE_DIR/$rpmFile
		fi
	else
		if [ -f $UNINSTALL_FILE_DIR/$PROD_NAME/$rpmFile ] ; then
			cat $UNINSTALL_FILE_DIR/$PROD_NAME/$rpmFile | while read rpmDetails
			do
				stringarray=($rpmDetails)
				rpmPkg=${stringarray[0]}
				rpmPkgName=${stringarray[1]}
				LinuxuninstallPkg $rpmPkgName
			done
			rm $UNINSTALL_FILE_DIR/$PROD_NAME/$rpmFile
		else
			str1=`gettext install "doesn't exist"`
			#write_and_log "$INSTR $rpmPkg $str1"
		fi
	fi
}
