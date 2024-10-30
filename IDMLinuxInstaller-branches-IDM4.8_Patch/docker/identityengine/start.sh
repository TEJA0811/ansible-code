#!/bin/bash -x

###########################################################
# This is a sample start up file for Identity Manager that
# links default stateful location (
# "/var/opt/novell/eDirectory", "/var/opt/novell/nici" 
# and "/etc/opt/novell/eDirectory") 
# to /config/idm location.
#
# @author: Pankaj Yogi
# @created: 04 Feb, 2018
###########################################################

# idm host location
CONF_HOME="/config/idm"

# variable pointing to edirectory conf default location
DEFAULT_CONF="/etc/opt/novell/eDirectory"

# variable pointing to edirectory conf custom location
CUSTOM_CONF=$CONF_HOME/eDirectory_conf

# variable pointing to edirectory default location
DEFAULT_EDIR="/var/opt/novell/eDirectory"

#variable pointing to edirectory custom location
CUSTOM_EDIR=$CONF_HOME/eDirectory_data

# variable pointing to nici default location
DEFAULT_NICI="/var/opt/novell/nici"

# variable pointing to nici custom location
CUSTOM_NICI=$CONF_HOME/nici_data

# variable pointing to configure log location
DEFAULT_CONFIGURE_LOG="/var/opt/netiq/idm/log"

# variable pointing to custom configure log location
CUSTOM_CONFIGURE_LOG=$CONF_HOME/log

# variable pointing to directory containing jar/so/rpm files
CUSTOM_MOUNTFILES_DIR=$CONF_HOME/mountfiles

#variable to detect if volume has configured data
VOLUME_CONFIGURED=0

# This function create the necessary links of destination directory
# at source directory. This function also do necessary steps required
# while creating link for tomcat.
createLinkIfRequired() {
	SOURCE=$1 # first parameter is source directory
	DEST=$2	# second parameter is destination directory
	
	if [ ! -d $DEST ] ; then
		mkdir -p $DEST
		#DEST_NOT_EXISTS=1
	#else 
		#DEST_NOT_EXISTS=0
	fi

	# In case SOURCE directory may not exist some time
	# so create directory first.
	if [ ! -e $SOURCE ] ; then
		mkdir -p $SOURCE
	fi
	
	# If source point to a directory we need to create the link
	if [ -d $SOURCE ] ; then
		# do not copy files from default location
		# to linked when linked location already exists.
		if [ $VOLUME_CONFIGURED -eq 0 ] ; then 
        		cp -r $SOURCE/* $DEST &> /dev/null
		fi
		echo $SOURCE | grep -q nici &> /dev/null
		if [ $? -eq 0 ]
		then
        		cp -r $SOURCE/* $DEST &> /dev/null
		fi
	       	rm -r $SOURCE &> /dev/null
        	ln -s $DEST $SOURCE &> /dev/null
		chown -R nds:nds $DEST
	fi
}

createBackLinkForFile()
{
	SOURCE_FILE=$1 # first file
	DEST_FILE=$2 # second file
	if [ -e $SOURCE_FILE ] ; then
		# rm if destination file exists
		if [ -e $DEST_FILE ] ; then
			rm $DEST_FILE &> /dev/null
		fi
		ln -s $SOURCE_FILE $DEST_FILE &> /dev/null
	fi
}

#function to detect if volume has configured state
setIfVolumeConfigured() {
	sh /nici-postinstall.sh &> /dev/null
	/var/opt/novell/nici/set_server_mode64 &> /dev/null
	if [ -f "$CUSTOM_CONF/conf/nds.conf" ] ; then
		VOLUME_CONFIGURED=1
	fi
}

setIfVolumeConfigured

# try to create backlinks if already configured
if [[ $VOLUME_CONFIGURED -eq 1 ]] ; then
	createBackLinkForFile $CONF_HOME/eba.p12 /home/nds/.eba.p12
else
	rm /home/nds/.eba.p12 &> /dev/null
	ln -s /config/idm/eba.p12 /home/nds/.eba.p12 &> /dev/null
fi

# mountfiles handling
if [ -d $CUSTOM_MOUNTFILES_DIR ]
then
	# link the jar files
	for jarfiles in $(ls $CUSTOM_MOUNTFILES_DIR/*.jar)
	do
		ln -s $jarfiles /opt/novell/eDirectory/lib/dirxml/classes/
	done
	# link the so files
	for sofiles in $(ls $CUSTOM_MOUNTFILES_DIR/*.so)
	do
		ln -s $sofiles /opt/novell/eDirectory/lib64/nds-modules/
	done
	# install the rpms
	if [ -z $MOUNTRPMOPTIONS ]
	then
		MOUNTRPMOPTIONS="--force"
	fi
	ls $CUSTOM_MOUNTFILES_DIR/*.rpm &> /dev/null
	if [ $? -eq 0 ]
	then
		rpm $MOUNTRPMOPTIONS -Uvh $CUSTOM_MOUNTFILES_DIR/*rpm
	fi
	chown -R nds:nds /etc/opt /opt /var/opt /tmp /dev &> /dev/null
	ldconfig
	setcap 'cap_net_bind_service=+ep' /opt/novell/eDirectory/sbin/ndsd
	setcap 'cap_net_bind_service=+ep' /opt/novell/eDirectory/bin/ndsconfig
	setcap 'cap_net_bind_service=+ep' /opt/novell/eDirectory/bin/dxcmd
fi
# Link edirectory data directory
createLinkIfRequired $DEFAULT_EDIR $CUSTOM_EDIR

# Link nici data directory
createLinkIfRequired $DEFAULT_NICI $CUSTOM_NICI

# Link edirectory conf directory
createLinkIfRequired $DEFAULT_CONF $CUSTOM_CONF

# Link configure log directory
createLinkIfRequired $DEFAULT_CONFIGURE_LOG $CUSTOM_CONFIGURE_LOG

if [ -f /var/opt/novell/eDirectory/log/PKIHealth.log ]
then
	cat /var/opt/novell/eDirectory/log/PKIHealth.log >> /var/opt/novell/eDirectory/log/PKIHealth-back.log
	>/var/opt/novell/eDirectory/log/PKIHealth.log
fi
#call startidm.sh

pid=0

# SIGUSR1-handler
my_handler() {
  echo "my_handler"
}

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]
  then
    #kill -SIGTERM "$pid"
    #wait "$pid"
    su -l nds -c "/opt/novell/eDirectory/bin/ndsmanage stopall"
    rm /var/opt/novell/eDirectory/data/ndsd.pid &> /dev/null
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

# run application
VOLUME_CONFIGURED=$VOLUME_CONFIGURED /startidm.sh &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

