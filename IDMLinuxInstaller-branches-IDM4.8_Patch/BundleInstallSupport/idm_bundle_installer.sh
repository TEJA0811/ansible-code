#!/bin/bash
##################################################################################
#
# Copyright © 2023 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
# Version : 1.2.0
# Shell Script name : idm_bundle_installer.sh
#
##################################################################################
echo ""
echo "		Read documentation before proceeding with the script run"
echo ""

#Path check when copied to different machine
loopthrough=true
while [ $loopthrough ]
do
	msg=`gettext install "Enter IDM 4.8 iso mount location : "`
	read -e -p "$msg" fullisolocation
	if [ -z $fullisolocation ] || [ "$fullisolocation" == "" ]
	then
		msg=`gettext install "Mount path cannot be empty. Enter a Valid Mount path "`
		echo $msg
		echo ""
		continue
	fi
	fullisolocation=$(realpath $fullisolocation)
	numbertocut=$(grep -o '/' <<< "$fullisolocation" | wc -l)
	((numbertocut++))
	fullisolocation=$(echo $fullisolocation | cut -d"/" -f-${numbertocut})
	grep -q "IDM 4.8.0" $fullisolocation/common/scripts/common_install_vars.sh
	if [ $? -eq 0 ]
	then
		break
	else
		msg=`gettext install "Entered location does not exist or is not valid. Re-enter valid mount path for IDM 4.8 "`
		echo $msg
		echo ""
		continue
	fi
done
while [ $loopthrough ]
do
	msg=`gettext install "Enter IDM 4.8.7 or above iso mount location : "`
	read -e -p "$msg" patchisolocation
	if [ -z $patchisolocation ] || [ "$patchisolocation" == "" ]
	then
		msg=`gettext install "Entered location does not exist or is not valid. Re-enter valid mount path for IDM 4.8.7 or above "`
		echo $msg
		echo ""
		continue
	fi
	patchisolocation=$(realpath $patchisolocation)
	numbertocut=$(grep -o '/' <<< "$patchisolocation" | wc -l)
	((numbertocut++))
	patchisolocation=$(echo $patchisolocation | cut -d"/" -f-${numbertocut})
	grep -q "IDM 4.8.[7-99]" $patchisolocation/common/scripts/common_install_vars.sh
	if [ $? -eq 0 ]
	then
		break
	else
		msg=`gettext install "Entered location does not exist or is not valid. Re-enter valid mount path for IDM 4.8.7 or above "`
		echo $msg
		echo ""
		continue
	fi
done
export rptrequired=true
while [ $loopthrough ]
do
	#487 bundles msgw driver rpm hence break
	unset rptrequired
	break
	msg=`gettext install "The installation requires MSGW driver version 4.2.2_P4 or above to be available as a ZIP archive. Enter the path to the MSGW zip archive ( Keep it empty if you don't want to configure reporting ) : "`
	read -e -p "$msg" msgwziplocation
	if [ -z $msgwziplocation ] || [ "$msgwziplocation" == "" ]
	then
		msg=`gettext install "Identity Reporting would not work well without MSGW driver version 4.2.2_P4 or above.  Proceed without updating MSGW rpm within newly created contents (y/n)"`
		read -e -p "$msg" yesorno
		if [ "$yesorno" == "no" ] || [ "$yesorno" == "n" ] || [ "$yesorno" == "N" ] || [ "$yesorno" == "No" ]
		then
			export rptrequired=true
		else
			unset rptrequired
		fi
	fi
	if [ -z $rptrequired ]
	then
		#Exiting msgw extract logic
		break
	fi
	if [ -z $msgwziplocation ] || [ "$msgwziplocation" == "" ]
	then
		msg=`gettext install "Entered path to MSGW driver ZIP archive does not exist or is not valid. Enter the valid path to MSGW ZIP archive "`
		echo $msg
		echo ""
		continue
	fi
	msgwziplocation=$(realpath $msgwziplocation)
	unzip -t $msgwziplocation | grep -q novell-DXMLMSGway
	if [ $? -eq 0 ]
	then
		break
	else
		msg=`gettext install "Entered path to MSGW driver ZIP archive does not exist or is not valid. Enter the valid path to MSGW ZIP archive"`
		echo $msg
		echo ""
		continue
	fi
done
while [ $loopthrough ]
do
	msg=`gettext install "The installer will create a folder named \"48and48x\"  under [/home] to copy the contents of 4.8 and 4.8.x ISO. Enter a different location or leave it blank for default location : [/home] "`
	read -e -p "$msg" baseisorefreshlocation
	if [ -z $baseisorefreshlocation ] || [ "$baseisorefreshlocation" == "" ]
	then
		baseisorefreshlocation=/home
	fi
	if [ ! -d $baseisorefreshlocation ]
	then
		msg=`gettext install "Entered path does not exist. Enter the valid path"`
		echo $msg
		echo ""
		continue
	fi
	baseisorefreshlocation=$(realpath $baseisorefreshlocation)
	#Required space set to 6 gb
	disksizerequired=6000000
	disksizeavailable=$(df -k $baseisorefreshlocation | grep -v Avail | awk '{print $4}')
	if [ $disksizeavailable -lt $disksizerequired ]
	then
		msg=`gettext install "In-sufficient disk space for copying the contents of 4.8 and 4.8.x ISO. A minimum of 6 GB is required. Enter a different location."`
		echo $msg
		echo ""
		continue
	else
		newisopath=${baseisorefreshlocation}/48and48x
		newisopath=$(realpath $newisopath)
		break
	fi
done
if [ -d $newisopath ]
then
	#Removing the previously created dir if exists
	rm -rf $newisopath
	mkdir -p $newisopath/48x
else
	mkdir -p $newisopath/48x
fi
if [ -f $patchisolocation/common/license/MicroFocusGPGPackageSign.pub ]
then
	rpm --import $patchisolocation/common/license/MicroFocusGPGPackageSign.pub &> /dev/null
fi
#Make a copy of 48 iso to /48and48x
cp -rpf $fullisolocation/* $newisopath/
cp -rpf $patchisolocation/* $newisopath/48x/
#Remove IDVault in /48and48x
rm -rf $newisopath/IDVault
#copy IDVault from 48x to /48
cp -rpf $patchisolocation/IDVault $newisopath/
echo yes | cp -rpf $fullisolocation/IDVault/scripts/* $newisopath/IDVault/scripts/
echo yes | cp -rpf $fullisolocation/IDVault/configure.sh $newisopath/IDVault/
#Overwrite novell-edirectory-xdaslog, novell-edirectory-xdaslog-conf and novell-edirectory-cefinstrument inside IDVault from IDM
rm -rf $newisopath/IDVault/setup/novell-edirectory-xdaslog-*rpm $newisopath/IDVault/setup/novell-edirectory-cefinstrument-*rpm
echo yes | cp $newisopath/48x/IDM/packages/common64/novell-edirectory-xdaslog-[0-9]*.rpm $newisopath/IDVault/setup/
echo yes | cp $newisopath/48x/IDM/packages/common/novell-edirectory-xdaslog-conf-[0-9]*.rpm $newisopath/IDVault/setup/
echo yes | cp $newisopath/48x/IDM/packages/common64/novell-edirectory-cefinstrument-[0-9]*.rpm $newisopath/IDVault/setup/
sed -i "s#postgresql-9.4.1212.jar#postgresql-42.6.0.jar#g" $newisopath/common/conf/prompts.conf
sed -i "s#IS_SYSTEM_CHECK_DONE=0#IS_SYSTEM_CHECK_DONE=1#g" $newisopath/common/scripts/common_install_vars.sh
sed -i "s#global_paths.sh#global_paths.sh\nexport RPMFORCE="--force"#g" $newisopath/48x/install.sh
sed -i "s@check_upgrade_supported@#check_upgrade_supported@g" $newisopath/48x/sspr/install.sh
sed -i "s@sspr_prompt_check_upgrade@#sspr_prompt_check_upgrade@g" $newisopath/48x/sspr/install.sh
sed -i "s@addSSPRLogoutURLToWhitelist@mkdir -p \${IDM_TEMP} \&\& addSSPRLogoutURLToWhitelist@g" $newisopath/48x/sspr/install.sh
sed -i 's@global_paths.sh@global_paths.sh\necho \"\";echo \"#################################################################\";echo \"#                                                               #\";echo \"# Please ensure the following recommendations before proceeding #\";echo \"#                                                               #\";echo \"#       1) Minimum number of processors required : 4            #\";echo \"#       2) Minimum amount of memory required     : 8 GB         #\";echo \"#                                                               #\";echo \"#################################################################\"@g' $newisopath/install.sh
sed -i "s#global_paths.sh#global_paths.sh\nif [ -f $newisopath/48x/common/license/MicroFocusGPGPackageSign.pub ];then rpm --import $newisopath/48x/common/license/MicroFocusGPGPackageSign.pub;fi#g" $newisopath/install.sh
sed -i "s#global_paths.sh#global_paths.sh\nif [ ! -f /sbin/chkconfig ];then echo /sbin/chkconfig not found hence exiting;exit 1;fi#g" $newisopath/install.sh
sed -i "s#global_paths.sh#global_paths.sh\nrpm -qa | grep -q ^unzip-;if [ \$? -ne 0 ];then echo unzip package not found hence exiting;exit 1;fi#g" $newisopath/install.sh
sed -i "s#echo \"3\"#echo \"1\"#g" $newisopath/48x/common/scripts/upgrade_check.sh
echo "cd /lib64/" >> $newisopath/install.sh
echo "find . -ilname 'libreadline.*' | grep -q libreadline.so.7" >> $newisopath/install.sh
echo "libreadlineBinaryPresence=\$?" >> $newisopath/install.sh
echo "if [ \$libreadlineBinaryPresence -ne 0 ]" >> $newisopath/install.sh
echo "then" >> $newisopath/install.sh
echo "  libreadlineBinaryLink=\$(ls -t /lib64/libreadline.* 2> /dev/null | grep -v libreadline.so.7 | grep libreadline -m 1)" >> $newisopath/install.sh
echo "  if [ ! -z \"\$libreadlineBinaryLink\" ] && [ \"\$libreadlineBinaryLink\" != \"\" ]" >> $newisopath/install.sh
echo "  then" >> $newisopath/install.sh
echo "    ln -sf \$libreadlineBinaryLink libreadline.so.7" >> $newisopath/install.sh
echo "  else" >> $newisopath/install.sh
echo "    str=\$(gettext install \"Missing mandatory library : /lib64/libreadline.so.7\")" >> $newisopath/install.sh
echo "    echo \$str" >> $newisopath/install.sh
echo "  fi" >> $newisopath/install.sh
echo "fi" >> $newisopath/install.sh
echo "cd - &> /dev/null" >> $newisopath/install.sh
#Using jre8 for designer headless
#grep "\${IDM_JRE_HOME}/bin:\$PATH \${DESIGNER_HOME}/Designer" common/scripts/install_common_libs.sh
echo "if [ -f \$IDM_INSTALL_HOME/48x/common/packages/java/netiq-jrex*zip ]" >> $newisopath/install.sh
echo "then" >> $newisopath/install.sh
echo "	mkdir -p /opt/netiq/commontemp" >> $newisopath/install.sh
echo "	cd /opt/netiq/commontemp" >> $newisopath/install.sh
echo "	unzip -oq \${IDM_INSTALL_HOME}/48x/common/packages/java/netiq-jrex*zip" >> $newisopath/install.sh
echo "	chown -R novlua:novlua /opt/netiq/commontemp" >> $newisopath/install.sh
echo "	cd - &> /dev/null" >> $newisopath/install.sh
echo "fi" >> $newisopath/install.sh
echo "rpm -e --nodeps novell-libstdc++6-5.3.1+r233831-14.1.x86_64 &> /dev/null" >> $newisopath/install.sh
echo "rpm -e --nodeps novell-libstdc++6-32bit-5.3.1+r233831-14.1.x86_64 &> /dev/null" >> $newisopath/install.sh
sed -i 's@\${IDM_JRE_HOME}/bin:\$PATH \${DESIGNER_HOME}/Designer@/opt/netiq/commontemp/jre8/bin:\$PATH \${DESIGNER_HOME}/Designer@g' $newisopath/common/scripts/install_common_libs.sh
sed -i 's@common_install_error.sh@common_install_error.sh\necho yes | rm -f /tmp/components.properties@g' $newisopath/configure.sh
sed -i 's#components.properties\"#components.properties\";echo \"\${SELECTION[compCount]}\" >> \"/tmp/components.properties\"#g' $newisopath/configure.sh
sed -i 's#source \$FILE_SILENT_INSTALL#source \$FILE_SILENT_INSTALL\nfor (( compCount = 0 ; compCount < $COUNT ; compCount++ ))\ndo\necho \"\${MENU_OPTIONS[compCount]}\" >> \"/tmp/components.properties\"\ndone#g' $newisopath/configure.sh
if [ ! -z $rptrequired ]
then
unzip -q $msgwziplocation -d $newisopath/
newmsgwdriver=$(find $newisopath/ -iname novell-DXMLMSGway*rpm | grep -v "IDM\/packages\/driver")
oldmsgwdriver=$(find $newisopath/ -iname novell-DXMLMSGway*rpm | grep "IDM\/packages\/driver")
echo yes | cp -f $newmsgwdriver $oldmsgwdriver
fi
echo "echo yes | cp /opt/novell/eDirectory/lib/dirxml/classes/javax.servlet-api*.jar /opt/netiq/common/jre/lib/ &> /dev/null" >> $newisopath/install.sh
#numbertocut is from patch iso - incrementing it
((numbertocut++))
for a in `find $patchisolocation -iname '*rpm'`
do
	echo $a | grep -Eq "iManager|idconsole|IDVault"
	if [ $? -eq 0 ]
	then
		continue
	fi
	rpmname=$(rpm -qp --queryformat '%{name}' $a)
	isorpmpath=$(dirname $a | cut -d"/" -f${numbertocut}-)
	#removing the rpms in the new iso path
	rm $newisopath/$isorpmpath/$rpmname-[0-9]*rpm &> /dev/null
	#copy every rpms from 48x to /48
	echo yes | cp $a $newisopath/$isorpmpath/
done
#If jre11 exists.. then overwrite
for a in `find $patchisolocation/IDVault/setup/jre11 -iname '*rpm'`
do
	rpmname=$(rpm -qp --queryformat '%{name}' $a)
	rm $newisopath/IDVault/setup/$rpmname-[0-9]*rpm
	echo yes | cp $patchisolocation/IDVault/setup/jre11/$rpmname-[0-9]*rpm $newisopath/IDVault/setup/
done
#Replacing install_info
echo yes | cp $patchisolocation/common/scripts/install_info.sh $newisopath/common/scripts/
#Enabling eDir for IPv6
#sed -i "s#-B @#-b #g" $newisopath/IDVault/configure.sh
echo IDVAULT_SKIP_UPDATE=true >> $newisopath/48x/engine.properties
echo INSTALL_ENGINE=true >> $newisopath/48x/engine.properties
echo INSTALL_IMAN=true >> $newisopath/48x/iman.properties
echo IDVAULT_SKIP_UPDATE=true >> $newisopath/48x/iman.properties
echo INSTALL_REPORTING=true >> $newisopath/48x/rpt.properties
echo IDVAULT_SKIP_UPDATE=true >> $newisopath/48x/rpt.properties
echo INSTALL_UA=true >> $newisopath/48x/ua.properties
echo IDVAULT_SKIP_UPDATE=true >> $newisopath/48x/ua.properties
echo INSTALL_SSPR=true >> $newisopath/48x/sspr/sspr.properties
echo IS_LICENSE_CHECK_DONE=1 >> $newisopath/48x/sspr/sspr.properties
echo "if [ -z \$ALLOW_UPGRADE ];then echo \"\";echo      Upgrade allowed from wrapper installer level only. Exiting...;echo \"\";exit 1;fi" | cat - $newisopath/48x/install.sh > temp && mv temp $newisopath/48x/install.sh
chmod +x $newisopath/48x/install.sh
echo "[ ! -f /etc/opt/netiq/idm/configure/IDM ] && grep -q IDM /tmp/components.properties;if [ \$? -eq 0 ];then echo Running upgrade scripts for Identity Manager Engine;ALLOW_UPGRADE=1 ./install.sh -s -f engine.properties &> /dev/null;fi" >> $newisopath/48x/upgrade.sh
echo "[ ! -f /etc/opt/netiq/idm/configure/iManager ] && grep -q iManager /tmp/components.properties;if [ \$? -eq 0 ];then echo Running upgrade scripts for iManager;ALLOW_UPGRADE=1 ./install.sh -s -f iman.properties &> /dev/null;fi" >> $newisopath/48x/upgrade.sh
echo "[ ! -f /etc/opt/netiq/idm/configure/user_application ] && grep -q user_application /tmp/components.properties;if [ \$? -eq 0 ];then echo Running upgrade scripts for Identity Applications;ALLOW_UPGRADE=1 ./install.sh -s -f ua.properties &> /dev/null;fi" >> $newisopath/48x/upgrade.sh
echo "[ ! -f /etc/opt/netiq/idm/configure/reporting ] && grep -q reporting /tmp/components.properties;if [ \$? -eq 0 ];then echo Running upgrade scripts for Identity Reporting;ALLOW_UPGRADE=1 ./install.sh -s -f rpt.properties &> /dev/null;fi" >> $newisopath/48x/upgrade.sh
echo "echo yes | rm -f /tmp/components.properties" >> $newisopath/48x/upgrade.sh
echo ". common/conf/global_variables.sh" >> $newisopath/48x/upgrade.sh
echo ". common/scripts/ui_format.sh" >> $newisopath/48x/upgrade.sh
echo ". common/scripts/commonlog.sh" >> $newisopath/48x/upgrade.sh
echo ". common/scripts/install_info.sh" >> $newisopath/48x/upgrade.sh
echo "log_file=/var/opt/netiq/idm/log/idmupgrade.log show_rptpatchinstall_info" >> $newisopath/48x/upgrade.sh
echo "if [ -z \$ALLOW_UPGRADE ];then echo \"\";echo      Upgrade allowed from wrapper installer level only. Exiting...;echo \"\";exit 1;fi" | cat - $newisopath/48x/sspr/install.sh > temp && mv temp $newisopath/48x/sspr/install.sh
chmod +x $newisopath/48x/sspr/install.sh
echo "if [ \$IS_WRAPPER_CFG_INST -eq 0 ]" >> $newisopath/sspr/configure.sh
echo "then" >> $newisopath/sspr/configure.sh
echo "cd \${IDM_INSTALL_HOME}/48x/sspr" >> $newisopath/sspr/configure.sh
echo "ALLOW_UPGRADE=1 ./install.sh -s -f sspr.properties &> /dev/null" >> $newisopath/sspr/configure.sh
echo "echo Re-starting the tomcat" >> $newisopath/sspr/configure.sh
echo "systemctl restart netiq-tomcat.service &> /dev/null" >> $newisopath/sspr/configure.sh
echo "fi" >> $newisopath/sspr/configure.sh
echo "echo Sleeping for 200s for the initial configuration to complete" >> $newisopath/configure.sh
echo "echo \"\"" >> $newisopath/configure.sh
echo "sleep 200s" >> $newisopath/configure.sh
echo "cd \${IDM_INSTALL_HOME}/48x/" >> $newisopath/configure.sh
echo "echo Running the upgrade scripts" >> $newisopath/configure.sh
echo "echo \"\"" >> $newisopath/configure.sh
echo "bash upgrade.sh" >> $newisopath/configure.sh

oracledbtypeservicesupport()
{
cat <<ENDOFTHEFILE > $newisopath/common/scripts/database_conn.sh
#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

database_conncheck()
{
    if [ "\$PROD_NAME" = "user_application" ]
    then
            if [ "\${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
            then
                DB_TYPE="Oracle"
                if [ "\${UA_ORACLE_DATABASE_TYPE}" == "service" ]
                then
                 UA_DB_CONNECTION_URL="jdbc:oracle:thin:@\${UA_WFE_DB_HOST}:\${UA_WFE_DB_PORT}/\${UA_DATABASE_NAME}"
                 WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@\${UA_WFE_DB_HOST}:\${UA_WFE_DB_PORT}/\${WFE_DATABASE_NAME}"
                elif [ "\${UA_ORACLE_DATABASE_TYPE}" == "sid" ]
                then
                 UA_DB_CONNECTION_URL="jdbc:oracle:thin:@\${UA_WFE_DB_HOST}:\${UA_WFE_DB_PORT}:\${UA_DATABASE_NAME}"
                 WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@\${UA_WFE_DB_HOST}:\${UA_WFE_DB_PORT}:\${WFE_DATABASE_NAME}"
		fi
            elif [ "\${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
            then
                DB_TYPE="SQL Server"
                UA_DB_CONNECTION_URL="jdbc:sqlserver://\${UA_WFE_DB_HOST}:\${UA_WFE_DB_PORT};DatabaseName=\${UA_DATABASE_NAME}"
                WFE_DB_CONNECTION_URL="jdbc:sqlserver://\${UA_WFE_DB_HOST}:\${UA_WFE_DB_PORT};DatabaseName=\${WFE_DATABASE_NAME}"
            fi
            if [ "\${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ] || [ "\${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
            then
                #verify_db_connection \${UA_WFE_DATABASE_USER} \${UA_WFE_DATABASE_PWD} \${UA_WFE_DB_HOST} \${UA_WFE_DB_PORT} \${UA_DATABASE_NAME} \${DB_TYPE} \${UA_WFE_DB_JDBC_DRIVER_JAR}
                verify_db_connection \${UA_WFE_DATABASE_USER} \${UA_WFE_DATABASE_PWD} "\${UA_DB_CONNECTION_URL}" "\${DB_TYPE}" \${UA_WFE_DB_JDBC_DRIVER_JAR}
		UA_DB_CONN_RET=\$?
                verify_db_connection \${UA_WFE_DATABASE_USER} \${UA_WFE_DATABASE_PWD} "\${WFE_DB_CONNECTION_URL}" "\${DB_TYPE}" \${UA_WFE_DB_JDBC_DRIVER_JAR}
		WFE_DB_CONN_RET=\$?
                DB_CONN_RET=0
		if [ \$UA_DB_CONN_RET -eq 1 ] || [ \$WFE_DB_CONN_RET -eq 1 ]
		then
			DB_CONN_RET=1
		fi

                if [ \$DB_CONN_RET -eq 1 ]
                then
                    disp_str=\`gettext install "Connection to database failed. Check whether database is running or parameters provided is valid. Run upgrade after correcting problem."\`
                    write_and_log "\$disp_str"
                exit
                else
                    disp_str=\`gettext install "Database connection successful."\`
                    write_and_log "\$disp_str"
                fi
            fi
    elif [ "\$PROD_NAME" = "reporting" ]
    then
    	    if [ "\${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	    then
                DB_TYPE="Oracle"
                if [ "\${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
                then
                   RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@\${RPT_DATABASE_HOST}:\${RPT_DATABASE_PORT}/\${RPT_DATABASE_NAME}"
                elif [ "\${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
                then
                   RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@\${RPT_DATABASE_HOST}:\${RPT_DATABASE_PORT}:\${RPT_DATABASE_NAME}"
                fi
	    elif [ "\${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
	    then
                DB_TYPE="SQL Server"
                RPT_DATABASE_CONNECTION_URL="jdbc:sqlserver://\${RPT_DATABASE_HOST}:\${RPT_DATABASE_PORT};DatabaseName=\${RPT_DATABASE_NAME}"
	    fi
            if [ "\${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ] || [ "\${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
            then
                verify_db_connection \${RPT_DATABASE_USER} \${RPT_DATABASE_SHARE_PASSWORD} "\${RPT_DATABASE_CONNECTION_URL}" "\${DB_TYPE}" \${RPT_DATABASE_JDBC_DRIVER_JAR}
                DB_CONN_RET=\$?
                if [ \$DB_CONN_RET -eq 1 ]
                then
                    disp_str=\`gettext install "Connection to database failed. Check database is running or parameters provided is valid. Run configure after correcting problem."\`
                    write_and_log "\$disp_str"
                    exit
                else
                    disp_str=\`gettext install "Database connection successful."\`
                    write_and_log "\$disp_str"
                fi
            fi
    fi
}
ENDOFTHEFILE
}
oracledbtypeservicesupport
#Removing iManager
rm -rf $newisopath/iManager $newisopath/48x/iManager
echo ""
echo "Proceed with install/configure"
echo ""
echo "	cd $newisopath"
echo "	./install.sh"
echo ""
echo "For standalone sspr installation, navigate to $newisopath/sspr and run install.sh"
echo ""
echo "After successful install continue with configuration"
echo ""
echo "	./configure.sh"
echo ""
echo "For standalone sspr installation, navigate to $newisopath/sspr and run configure.sh"
echo ""
echo "You can also mount $newisopath across different machines if you want to do distributed installation"
echo ""


