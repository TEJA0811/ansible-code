#!/bin/bash
##################################################################################
#
# Copyright © 2018 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################
removesslcryptolinks()
{
   if [ -f /usr/lib64/libssl.so.1.0.0 ]
   then
	ls -l /usr/lib64/libssl.so.1.0.0 | grep -q /opt/netiq/common/openssl/lib64/libssl.so.1.0.0
	[ $? -eq 0 ] && rm /usr/lib64/libssl.so.1.0.0
   fi
   if [ -f /usr/lib64/libcrypto.so.1.0.0 ]
   then
	ls -l /usr/lib64/libcrypto.so.1.0.0 | grep -q /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0
	[ $? -eq 0 ] && rm /usr/lib64/libcrypto.so.1.0.0
   fi
}
if [ ! -d /var/opt/netiq/idm/log/ ]
then
	mkdir -p /var/opt/netiq/idm/log/
fi
newDirStrucuture=false
if [ -d /opt/netiq/idm/postgres ]
then
	newDirStrucuture=true
fi
PGLOG=/var/opt/netiq/idm/log/pg-upgrade.log
loopISOPrompt=true
txtgrn=$(tput setaf 2)
txtylw=$(tput setaf 3)
txtrst=$(tput sgr0)
echo ""
scriptDirtemp=$(dirname $0)
scriptDir=$(readlink -m ${scriptDirtemp})
postgreRpmDir=$(readlink -m ${scriptDir}/../packages/postgres/)
netiqopensslrpmdir=$(readlink -m ${scriptDir}/../../IDM/packages/OpenSSL/x86_64/)
if [ ! -f ${postgreRpmDir}/netiq-postgresql-*rpm ]
then
	msg=$(gettext install "netiq-postgresql rpm is not available in the ISO/zip")
	echo $msg | tee -a $PGLOG
	echo ""
	exit 1
fi
if [ -f ${netiqopensslrpmdir}/netiq-openssl-*rpm ]
then
	rpm -Uvh ${netiqopensslrpmdir}/netiq-openssl-*rpm &> /tmp/netiq-openssl-rpm-install.log
	grep "Failed dependencies" /tmp/netiq-openssl-rpm-install.log &> /dev/null
	if [ $? -eq 0 ]
	then
		rm -f /tmp/netiq-openssl-rpm-install.log
		msg=$(gettext install "${netiqopensslrpmdir}/netiq-openssl-*rpm could not be installed/upgraded due to dependency issues.  Try upgrading netiq-openssl manually after due diligence and start again")
		echo $msg | tee -a $PGLOG
		echo ""
		exit 1
	fi
	rm -f /tmp/netiq-openssl-rpm-install.log
fi
export LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH 
newpgVersion=$(rpm -qp --queryformat '%{VERSION}' ${postgreRpmDir}/netiq-postgresql-*rpm)
str=$(gettext install "Missing mandatory library :")
cd /lib64
find . -ilname 'libreadline.*' | grep -q libreadline.so.7
libreadlineBinaryPresence=$?
if [ $libreadlineBinaryPresence -ne 0 ]
then
  libreadlineBinaryLink=$(ls -t /lib64/libreadline.* 2> /dev/null | grep -v libreadline.so.7 | grep libreadline -m 1)
  if [ ! -z "$libreadlineBinaryLink" ] && [ "$libreadlineBinaryLink" != "" ]
  then
    ln -sf $libreadlineBinaryLink libreadline.so.7
  else
    write_and_log "$str /lib64/libreadline.so.7"
    exit 1
  fi
fi
cd - &> /dev/null
if ! rpm -qa | grep -q netiq-openssl
then
	# Need to re-link with available ssl binaries in the system
	cd /usr/lib64
	find . -ilname 'libssl*' | grep -q libssl.so.1.0.0
	libsslBinaryPresence=$?
	find . -ilname 'libcrypto*' | grep -q libcrypto.so.1.0.0
	libcryptoBinaryPresence=$?
	if [ $libsslBinaryPresence -ne 0 ]
	then
		libsslBinaryLink=$(ls -t libssl.* 2> /dev/null | grep libssl -m 1)
		if [ ! -z "$libsslBinaryLink" ] && [ "$libsslBinaryLink" != "" ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf $libsslBinaryLink libssl.so.1.0.0
		else
			echo $str /usr/lib64/libssl.so.1.0.0
			exit 1
		fi
	fi
	if [ $libcryptoBinaryPresence -ne 0 ]
	then
		libcryptoBinaryLink=$(ls -t libcrypto.* 2> /dev/null | grep libcrypto -m 1)
		if [ ! -z "$libcryptoBinaryLink" ] && [ "$libcryptoBinaryLink" != "" ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf $libcryptoBinaryLink libcrypto.so.1.0.0
		else
			echo $str /usr/lib64/libcrypto.so.1.0.0
			exit 1
		fi
	fi
	cd - &> /dev/null
else
	# Linking with locally built ssl binaries in the system
	cd /usr/lib64
	if [ -f /opt/netiq/common/openssl/lib64/libssl.so.1.0.0 ] && [ -f /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0 ]
	then
		if [ ! -f libssl.so.1.0.0 ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf /opt/netiq/common/openssl/lib64/libssl.so.1.0.0 libssl.so.1.0.0
		fi
		if [ ! -f libcrypto.so.1.0.0 ]
		then
			echo "Do nothing" &> /dev/null
			#ln -sf /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0 libcrypto.so.1.0.0
		fi
	else
		# Error out
		msg=$(gettext install "One/Both of Mandatory libraries missing : /opt/netiq/common/openssl/lib64/libssl.so.1.0.0 /opt/netiq/common/openssl/lib64/libcrypto.so.1.0.0 ")
		echo $msg | tee -a $PGLOG
		echo ""
		exit 1
	fi
	cd - &> /dev/null
fi
rpm -Uvh --test ${postgreRpmDir}/netiq-postgresql-*rpm &> /dev/null
retCode=$?
RPMFORCE=""
if [ $retCode -eq 1 ]
then
	msg=`gettext install "Looks like the necessary Postgres version is already up-to-date"`
	echo $msg | tee -a $PGLOG
	msg=`gettext install "Do you really want to continue? [y/n]"`
	read -e -p "$msg" yesorno
	if [ "$yesorno" == "no" ] || [ "$yesorno" == "n" ] || [ "$yesorno" == "N" ] || [ "$yesorno" == "No" ]
	then
		echo ""
		exit 1
	fi
	RPMFORCE="--force"
elif [ $retCode -eq 2 ]
then
	msg=$(gettext install "Installed postgre version is newer than the one in ISO/zip")
	echo $msg | tee -a $PGLOG
	echo ""
	exit 1
fi
function checkDir()
{
	# For validating the folder
	# Usage
	# checkDir <Directory-variable> <Directory-definition> <optional-file-to-check-under-it>
	loopthrough=true
	while [ $loopthrough ]
	do
		eval "dirVarValue=\$$1"
		dirDefinition="$2"
		fileTocheck="$3"
		prompt_enter=`gettext install "Enter"`
		if [ "$dirVarValue" == "" ]
		then
			read -e -p "$prompt_enter $dirDefinition : " dirTocheck
		else
			read -e -p "$prompt_enter $dirDefinition [$dirVarValue] : " dirTocheck
			if [ "$dirTocheck" = "" ]
			then
				dirTocheck="$dirVarValue"
			fi
		fi
		if [ "$fileTocheck" != "" ]
		then
			fileLocation=`find "$dirTocheck" -iname "$fileTocheck" 2> /dev/null`
			ls "$fileLocation" &> /dev/null
			if [ $? -ne 0 ]
			then
				error_filemsg1=`gettext install "Entered"`
				error_filemsg2=`gettext install "is wrong. Enter correct details"`
				echo $error_filemsg1 $dirDefinition $error_filemsg2
				echo ""
				continue
			else
				if [ "$fileTocheck" = "createdb" ]
				then
					dirTocheck=$(dirname `dirname $fileLocation`)
				else
					dirTocheck=`dirname $fileLocation`
				fi
				eval "$1='${dirTocheck}'"
				echo ""
				break
			fi
		else
			ls ${dirTocheck} &> /dev/null
			if [ $? -eq 0 ]
			then
				nooffiles=$(ls ${dirTocheck} 2> /dev/null | wc -l)
				if [ "$nooffiles" != 0 ]
				then
					err_folder=$(gettext install "Entered directory must be empty")
					echo $err_folder
					echo ""
					continue
				fi
			fi
			eval "$1='${dirTocheck}'"
			echo ""
			break
		fi
	done
}
prompt_existingpgDir=`gettext install "Existing Postgres install location"`
prompt_existingpgDataDir=`gettext install "Existing Postgres Data Directory"`
prompt_newpgDataDir=`gettext install "New Postgres Data Directory"`
prompt_existingpgPass=`gettext install "Existing Postgres password"`
existing_pgDir=/opt/netiq/idm/apps/postgres
if [ "$newDirStrucuture" == "true" ]
then
	existing_pgDir=/opt/netiq/idm/postgres
fi
checkDir existing_pgDir "$prompt_existingpgDir" createdb 
existing_pgDataDir=/opt/netiq/idm/apps/postgres/data
if [ "$newDirStrucuture" == "true" ]
then
	existing_pgDataDir=/opt/netiq/idm/postgres/data
fi
checkDir existing_pgDataDir "$prompt_existingpgDataDir" pg_hba.conf 
checkpassword=true
langformat=$(su -s /bin/sh - postgres -c "localectl | grep LANG | cut -d"=" -f2-")
if [ -z $langformat ] || [ "$langformat" == "" ]
then
	langformat=$(su -s /bin/sh - postgres -c "localectl | grep LC_CTYPE | cut -d"=" -f2-")
fi
if [ -z $langformat ] || [ "$langformat" == "" ]
then
	langformat=en_US.UTF-8
fi
while [ $checkpassword ]
do
	wrongpassword=1
	prompt_existingpgPass=`gettext install "Enter Existing Postgres Database password"`
	stty -echo
	read -e -p "${prompt_existingpgPass} : " password
	echo ""
	stty echo
	if [ "$password" == "" ]
	then
		wrongpassword=1
	else
		escapedpassword=$(echo "$password" | sed 's/./\\&/g')
		su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH PGPASSWORD=${escapedpassword} LANG=${langformat} ${existing_pgDir}/bin/psql -l" &> /dev/null
		wrongpassword=`echo $?`
	fi
	if [ $wrongpassword -ne 0 ]
	then
		error_wrongpass=`gettext install "Entered password is wrong. Enter correct credentials."`
		echo $error_wrongpass
		echo ""
		continue
	else
		echo ""
		break
	fi
done
original_pgDataDir=$existing_pgDataDir
if [ -f $existing_pgDataDir/postgresql.conf ]
then
	grep -q ^ssl $existing_pgDataDir/postgresql.conf
	if [ $? -eq 0 ]
	then
		sslcertdirname=$(grep ssl_cert_file $existing_pgDataDir/postgresql.conf | awk -F "'" '{print $2}' | xargs dirname)
		sslcertbasename=$(grep ssl_cert_file $existing_pgDataDir/postgresql.conf | awk -F "'" '{print $2}' | xargs basename)
		if [ "$sslcertdirname" == "." ]
		then
			cp $existing_pgDataDir/$sslcertbasename ~/
		else
			cp $sslcertdirname/$sslcertbasename ~/
		fi
		sslkeydirname=$(grep ssl_key_file $existing_pgDataDir/postgresql.conf | awk -F "'" '{print $2}' | xargs dirname)
		sslkeybasename=$(grep ssl_key_file $existing_pgDataDir/postgresql.conf | awk -F "'" '{print $2}' | xargs basename)
		if [ "$sslkeydirname" == "." ]
		then
			cp $existing_pgDataDir/$sslkeybasename ~/
		else
			cp $sslkeydirname/$sslkeybasename ~/
		fi
	fi
fi
export PGPASSWORD=${escapedpassword}
timestamp=`date +"%Y%m%d%H%M%S"`
new_pgDataDir=/opt/netiq/idm/postgres/data
if [ -d $new_pgDataDir ]
then
	new_pgDataDir=/opt/netiq/idm/postgres${newpgVersion}/data
fi
if [ ! -z "$SPECIFY_NEW_PG_DATA_DIR" ]
then
	checkDir new_pgDataDir "$prompt_newpgDataDir" 
else
	new_pgDataDir=$(readlink -m $existing_pgDataDir/../../postgres${newpgVersion}/data/)
fi

# Check the size
olddatasize=$(du -s $existing_pgDataDir | awk '{print $1}')
# Adding 1 GB additionally to the old data size
olddatasize=$(expr $olddatasize + 1000000)
deletelater=false
if [ ! -d $new_pgDataDir ]
then
	mkdir -p $new_pgDataDir
	deletelater=true
fi
newdatasize=$(df -k $new_pgDataDir | grep -v Avail | awk '{print $4}')
deletecreatedfolders()
{
	if [ "$deletelater" == "true" ]
	then
		yes | rm -rf $new_pgDataDir
		nooffiles=$(ls /opt/netiq/idm/postgres 2> /dev/null | wc -l)
		if [ $nooffiles == 0 ]
		then
			rm -rf /opt/netiq/idm/postgres
		fi
	fi
}
if [ $newdatasize -lt $olddatasize ]
then
	if [ ! -z "$SPECIFY_NEW_PG_DATA_DIR" ]
	then
		msg=$(gettext install "Entered new postgres data directory does not have sufficient disk space.  Exiting...")
	else
		msg=$(gettext install "Backup base directory $(readlink -m $existing_pgDataDir/../../) does not have sufficient disk space.  Exiting...")
	fi
	echo $msg | tee -a $PGLOG
	echo "" | tee -a $PGLOG
	deletecreatedfolders
	exit 1
fi
deletecreatedfolders
# Check the size

echo "${txtylw}"
echo "###############################################################"
echo ""
msg=`gettext install "Upgrading : Postgres Database to"`
echo "            $msg $newpgVersion"
echo ""
echo "###############################################################"
echo "${txtgrn}"
echo ""
echo ""
msg=`gettext install "Refer to $PGLOG for more information"`
echo "$msg"
echo "${txtrst}"

# Prompting ends here

echo ""
msg=`gettext install "Stopping the Postgres service"`
echo ${msg} | tee -a $PGLOG
echo "" | tee -a $PGLOG
su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH ${existing_pgDir}/bin/pg_ctl stop -w -D $existing_pgDataDir -m fast" >> $PGLOG

msg=`gettext install "Installing new Postgres database"`
echo ${msg} | tee -a $PGLOG
echo "" | tee -a $PGLOG
PGLOGTEMP=/var/opt/netiq/idm/log/pg-upgrade-temp.log
pg966plus=false
DATETODAY=$(date +%Y%m%d%H%M)
if [ -d /opt/netiq/idm/postgres ]
then
	pgBackDirVersion=$(rpm -q --queryformat '%{VERSION}' netiq-postgresql)
	pgBackDir=/opt/netiq/idm/postgres$pgBackDirVersion-$DATETODAY-backup
	rm -rf $pgBackDir
	mv /opt/netiq/idm/postgres $pgBackDir
	pg966plus=true
	rpm -e netiq-postgresql-9.6.6-0.noarch &> /dev/null
	# Couldn't do this earlier as there is a condition with pg966 rpm which removes pg dir post install
	yes | cp -rpf $pgBackDir /opt/netiq/idm/postgres
fi
if [ -d /opt/netiq/idm/apps/postgres ] && [ "$pg966plus" == "false" ]
then
	pgBackDir=/opt/netiq/idm/apps/postgres-$DATETODAY-backup
	rm -rf $pgBackDir
	mv /opt/netiq/idm/apps/postgres $pgBackDir
	existing_pgDataDir=$(readlink -m $existing_pgDataDir)
	echo $existing_pgDataDir | grep -q /opt/netiq/idm/apps/postgres
	if [ $? -eq 0 ]
	then
		existing_pgDataDir=$(echo $existing_pgDataDir | sed -e "s#/opt/netiq/idm/apps/postgres#$pgBackDir#g")
	fi
fi
if [ -z "$pgBackDir" ]
then
	# Condition where /opt/netiq/idm/apps/postgres and /opt/netiq/idm/postgres doesn't exist
	existing_pgDir=$(readlink -m $existing_pgDir)
	pgBackDir=$existing_pgDir-$DATETODAY-backup
	rm -rf $pgBackDir
	mv $existing_pgDir $pgBackDir
	existing_pgDataDir=$(readlink -m $existing_pgDataDir)
	echo $existing_pgDataDir | grep -q $existing_pgDir
	if [ $? -eq 0 ]
	then
		existing_pgDataDir=$(echo $existing_pgDataDir | sed -e "s#$existing_pgDir#$pgBackDir#g")
	fi
fi
rpm ${RPMFORCE} -Uvh ${postgreRpmDir}/netiq-postgresql-*rpm &> $PGLOGTEMP
if [ true ]
then
	existing_pgDataDir=$(readlink -m $existing_pgDataDir)
	existing_pgDir=$(readlink -m $existing_pgDir)
	echo $existing_pgDataDir | grep -q $existing_pgDir/
	if [ $? -eq 0 ]
	then
		# Removing the existing pg data dir here since the same is already backed up
		yes | rm -rf $existing_pgDataDir
		existing_pgDataDir=$(echo $existing_pgDataDir | sed -e "s#$existing_pgDir#$pgBackDir#g")
	fi
	existing_pgDir=$pgBackDir
	msg=$(gettext install "Backed up postgres data directory @")
	echo ${msg} ${existing_pgDataDir} | tee -a $PGLOG
	echo "" | tee -a $PGLOG
fi
cat $PGLOGTEMP >> $PGLOG
rm -f $PGLOGTEMP
mkdir -p "${new_pgDataDir}"
chown -R postgres:postgres /opt/netiq/idm/postgres "${new_pgDataDir}"
export PG_HOME=/opt/netiq/idm/postgres
msg=`gettext install "Initializing the database"`
echo ${msg} | tee -a $PGLOG
usermod -d /opt/netiq/idm/postgres postgres
su -s /bin/sh - postgres -c "LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH LANG=${langformat} /opt/netiq/idm/postgres/bin/initdb -D '${new_pgDataDir}'" &> $PGLOGTEMP
cat $PGLOGTEMP >> $PGLOG
rm -f $PGLOGTEMP
echo "" | tee -a $PGLOG
sed -i.bak "s#${original_pgDataDir}#${existing_pgDataDir}#g" ${existing_pgDataDir}/postgresql.conf &> /dev/null
su -s /bin/sh - postgres -c "export LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64/:$LD_LIBRARY_PATH && export PG_HOME=/opt/netiq/idm/postgres && export PGPASSWORD=${PGPASSWORD} && cd /opt/netiq/idm/postgres/ && /opt/netiq/idm/postgres/bin/pg_upgrade --old-datadir '${existing_pgDataDir}' --new-datadir '${new_pgDataDir}' --old-bindir '${existing_pgDir}/bin' --new-bindir /opt/netiq/idm/postgres/bin" >> $PGLOG
if [ $? -ne 0 ]
then
	msg=`gettext install "Upgrading database failed"`
	echo ${msg} | tee -a $PGLOG
	echo "" | tee -a $PGLOG
	exit 1
else
	msg=`gettext install "Upgrading database successful"`
        echo ${msg} | tee -a $PGLOG
	echo "" | tee -a $PGLOG
fi
msg=`gettext install "Updating the pg_hba.conf file to trust the server network"`
echo ${msg} | tee -a $PGLOG
echo "" | tee -a $PGLOG
echo "host all all 0.0.0.0/0 trust" >> "${new_pgDataDir}"/pg_hba.conf
msg=`gettext install "Updating the postgresql.conf to ensure that your PostgreSQL instance listens on other network instances, other than localhost"`
echo ${msg} | tee -a $PGLOG
echo "" | tee -a $PGLOG
echo "listen_addresses = '*'" >> "${new_pgDataDir}"/postgresql.conf
mkdir -p "${new_pgDataDir}"/pg_log
chown -R postgres:postgres "${new_pgDataDir}"/pg_log
chmod -R 700 "${new_pgDataDir}"/pg_log
chmod 755 /etc/init.d/netiq-postgresql
sed -i.bak "s#local   all             all                                     trust#local   all             all                                     md5#g" "${new_pgDataDir}"/pg_hba.conf &> /dev/null
sed -i.bak "s#host    all             all             127.0.0.1/32            trust#host    all             all             127.0.0.1/32            md5#g" "${new_pgDataDir}"/pg_hba.conf &> /dev/null
sed -i.bak "s#host    all             all             ::1/128                 trust#host    all             all             ::1/128                 md5#g" "${new_pgDataDir}"/pg_hba.conf &> /dev/null
sed -i.bak "s#host all all 0.0.0.0/0 trust#host all all 0.0.0.0/0 md5#g" "${new_pgDataDir}"/pg_hba.conf &> /dev/null
rm "${new_pgDataDir}"/pg_hba.conf.bak &> /dev/null
# Renaming the new pg data dir to existing pg data dir - exising pg data dir already backed up
if [ ! -d $original_pgDataDir ] && [ -z "$SPECIFY_NEW_PG_DATA_DIR" ]
then
	new_pgDataDirBase=$(readlink -m $new_pgDataDir/../)
	original_pgDataDirBase=$(readlink -m $original_pgDataDir/../)
	if [ ! -d ${original_pgDataDirBase} ]
	then
		mkdir -p ${original_pgDataDirBase}
	fi
	mv ${new_pgDataDir} ${original_pgDataDirBase}
	nooffiles=$(ls ${new_pgDataDirBase} 2> /dev/null | wc -l)
	if [ "$nooffiles" == 0 ]
	then
		rm -rf ${new_pgDataDirBase}
	fi
	new_pgDataDir=${original_pgDataDir}
fi
sed -i.bak "s#/opt/netiq/idm/postgres/data#${new_pgDataDir}#g" /etc/init.d/netiq-postgresql &> /dev/null 
if [ ! -z "$sslcertbasename" ] || [ ! -z "$sslkeybasename" ]
then
	if [ "$sslcertbasename" != "" ] || [ "$sslkeybasename" != "" ]
	then
		echo "ssl = on" >> ${new_pgDataDir}/postgresql.conf
	fi
fi
if [ ! -z "$sslcertbasename" ]
then
	mv ~/$sslcertbasename ${new_pgDataDir}
	chown postgres:postgres ${new_pgDataDir}/$sslcertbasename
	echo "ssl_cert_file = '${new_pgDataDir}/$sslcertbasename'" >> ${new_pgDataDir}/postgresql.conf
fi
if [ ! -z "$sslkeybasename" ]
then
	mv ~/$sslkeybasename ${new_pgDataDir}
	chown postgres:postgres ${new_pgDataDir}/$sslkeybasename
	echo "ssl_key_file = '${new_pgDataDir}/$sslkeybasename'" >> ${new_pgDataDir}/postgresql.conf
fi
msg=`gettext install "Restarting the PostgreSQL service"`
echo ${msg} | tee -a $PGLOG
echo "" | tee -a $PGLOG
systemctl enable netiq-postgresql.service &> /dev/null
systemctl restart netiq-postgresql
su -s /bin/sh - postgres -c 'if [ -f .bashrc ]; then grep -i LD_LIBRARY_PATH .bashrc &> /dev/null; if [ $? -ne 0 ]; then chmod 666 .bashrc; echo "export LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64:\$LD_LIBRARY_PATH" >> .bashrc ;chmod 644 .bashrc ;fi;else echo "export LD_LIBRARY_PATH=/opt/netiq/common/openssl/lib64:\$LD_LIBRARY_PATH" >> .bashrc ; fi'
removesslcryptolinks
