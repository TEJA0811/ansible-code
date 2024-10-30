
# reporting host location
CONF_HOME="/config/reporting"

# variable pointing to tomcat default location
DEFAULT_TOMCAT="/opt/netiq/idm/apps/tomcat"

# variable pointing to tomcat custom location
CUSTOM_TOMCAT=$CONF_HOME/tomcat

#variable to detect if volume has configured data
VOLUME_CONFIGURED=0

#jre8/jre11 code block
JRE8CODE_BLOCK=1

#function to create back links for files
createBackLinkForFile() {
        SOURCE_FILE=$1 # first file
        DEST_FILE=$2 # second file

	if [ -e $SOURCE_FILE ] ; then
		rm $DEST_FILE &> /dev/null
                ln -s $SOURCE_FILE $DEST_FILE
	fi
}

createBackLinkFiles()
{
	createBackLinkForFile $CONF_HOME/configupdate/configupdate.sh.properties /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
	createBackLinkForFile $CUSTOM_TOMCAT/bin/setenv.sh $DEFAULT_TOMCAT/bin/setenv.sh
}

CopyBackEditedFiles()
{
	mkdir -p $CONF_HOME/configupdate/ $CUSTOM_TOMCAT/bin/ &> /dev/null
	cp /opt/netiq/idm/apps/configupdate/configupdate.sh.properties $CONF_HOME/configupdate/configupdate.sh.properties
	cp $DEFAULT_TOMCAT/bin/setenv.sh $CUSTOM_TOMCAT/bin/setenv.sh
}

#function to detect if volume has configured state
setIfVolumeConfigured() {
	if [ -f "$CUSTOM_TOMCAT/conf/ism-configuration.properties" ] ; then
		VOLUME_CONFIGURED=1
	fi
}

setIDM_INSTALL_HOME()
{
	#Call it only in the case of patching
	if [ -d /idmpatch ]
	then
		IDM_INSTALL_HOME=/idmpatch/
	else
		IDM_INSTALL_HOME=/idm/
	fi
}
