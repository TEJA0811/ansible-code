get_14_digit_random_number()
{
    local number=$RANDOM;
    let "number %= 9";
    let "number = number + 1";
    local range=10;
    for i in {1..13}; do
      r=$RANDOM;
      let "r %= $range";
      number="$number""$r";
    done;
    echo $number
}

fourteendigitnumber=$(get_14_digit_random_number)
echo fourteendigitnumber=$fourteendigitnumber > /test
# osp host location
CONF_HOME="/config/osp"
mkdir -p $CONF_HOME
ORG_OSP_REPLICA_COUNT=$OSP_REPLICA_COUNT
if [ ! -z $OSP_REPLICA_COUNT ] && [ $OSP_REPLICA_COUNT -gt 1 ]
then
	while [ $OSP_REPLICA_COUNT -gt 1 ]
	do
		if [ -f $CONF_HOME/controlling ]
		then
			controlnumber=$(cat $CONF_HOME/controlling)
			if [ -z $controlnumber ]
			then
				exitCodeforcontrol=1
			else
				grep -q $controlnumber /config/osp/transaction-lock-file
				exitCodeforcontrol=$?
			fi
			if [ $exitCodeforcontrol -eq 0 ]
			then
				#skip and continue with next conf_home
				CONF_HOME="/config/osp${OSP_REPLICA_COUNT}"
				(( OSP_REPLICA_COUNT-- ))
				continue
			else
				#rm -f $CONF_HOME/transaction-lock-file
				break
			fi
		else
			#Nobody is controlling hence break out to take control
			break
		fi
	done
fi
#Sleeping for 30 seconds so that transaction lock file gets deleted across if need be
sleep 30s
OSP_REPLICA_COUNT=$ORG_OSP_REPLICA_COUNT
if [ ! -z $OSP_REPLICA_COUNT ] && [ $OSP_REPLICA_COUNT -gt 1 ]
then
	#Create all the data layer's parent directory here
	while [ $OSP_REPLICA_COUNT -gt 1 ]
	do
		#echo $OSP_REPLICA_COUNT
		mkdir -p "/config/osp${OSP_REPLICA_COUNT}"
		(( OSP_REPLICA_COUNT-- ))
	done
fi
OSP_REPLICA_COUNT=$ORG_OSP_REPLICA_COUNT
firstinstancenotcompleted=true
echo $fourteendigitnumber >> /config/osp/transaction-lock-file
head -1 /config/osp/transaction-lock-file | grep -q $fourteendigitnumber
entrymadefirst=$?
while [ true ]
do
	if [ "$firstinstancenotcompleted" == "false" ]
	then
		# First instance completed configuring
		echo $fourteendigitnumber >> $CONF_HOME/transaction-lock-file
		head -1 $CONF_HOME/transaction-lock-file | grep -q $fourteendigitnumber
		entrymadefirst=$?
	fi
	if [ ${entrymadefirst} -ne 0 ]
	then
		#Already another instance is working on the data layer
		while [ $firstinstancenotcompleted ]
		do
			#wait till the first instance is configured
			#/config/osp is the first instance data layer
			grep -q "Deploying web application archive" /config/osp/tomcat/logs/catalina.out &> /dev/null
			firstlogcheck=$?
			osprpmversion=$(rpm -q --queryformat '%{version}' netiq-osp)
			grep -q "using server version: ${osprpmversion}" /config/osp/tomcat/logs/catalina.out &> /dev/null
			secondlogcheck=$?
			if [ ${firstlogcheck} -ne 0 ] || [ ${secondlogcheck} -ne 0 ] || [ ! -f /config/osp/osp/osp.jks ]
			then
				sleep 10s
				continue
			else
				firstinstancenotcompleted=false
				break
			fi
		done
		## Need a variable to fetch the number of instances for osp
		# Say the number is three for now ie., OSP_REPLICA_COUNT=3
		#OSP_REPLICA_COUNT=3
		if [ ! -z $OSP_REPLICA_COUNT ] && [ $OSP_REPLICA_COUNT -gt 1 ]
		then
			#Start the other instances but with their own unique data layer where possible
			CONF_HOME="/config/osp${OSP_REPLICA_COUNT}"
			(( OSP_REPLICA_COUNT-- ))
			continue
		fi
	else
		#Adding the Controlling instance id with the unique random number
		echo $fourteendigitnumber > $CONF_HOME/controlling
	fi
	#Exit the loop at the end
	#Copying the configuration of first instance to all and editing the engine id to be unique
	if [ ${CONF_HOME} != "/config/osp" ]
	then
		#Do it only once
		if [ ! -f ${CONF_HOME}/copiedfromfirstinstance ]
		then
			cp -rpf /config/osp/{osp,log,tomcat,version.properties} ${CONF_HOME}/
			#tomcat/conf will be linked from the first instance
			rm -rf ${CONF_HOME}/tomcat/conf /opt/netiq/idm/apps/tomcat/conf
			#Giving unique value for workflow engine id
			touch ${CONF_HOME}/copiedfromfirstinstance
		fi
	fi
	break
done
echo OSP_REPLICA_COUNT=$ORG_OSP_REPLICA_COUNT > /commonfunctions-sub.sh
echo CONF_HOME=$CONF_HOME >> /commonfunctions-sub.sh
#STARTINGPOINT

# variable pointing to osp default location
DEFAULT_OSP="/opt/netiq/idm/apps/osp"

#variable pointing to osp custom location
CUSTOM_OSP=$CONF_HOME/osp

# variable pointing to tomcat default location
DEFAULT_TOMCAT="/opt/netiq/idm/apps/tomcat"

# variable pointing to tomcat custom location
CUSTOM_TOMCAT=$CONF_HOME/tomcat

# variable OSP_JKS
OSP_JKS="osp.jks"

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
	createBackLinkForFile $CUSTOM_OSP/$OSP_JKS $DEFAULT_OSP/$OSP_JKS
	createBackLinkForFile /config/osp/configupdate/configupdate.sh.properties /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
	createBackLinkForFile $CUSTOM_TOMCAT/bin/setenv.sh $DEFAULT_TOMCAT/bin/setenv.sh
}

CopyBackEditedFiles()
{
	mkdir -p /config/osp/configupdate/ $CUSTOM_TOMCAT/bin/ &> /dev/null
	cp $DEFAULT_OSP/$OSP_JKS $CUSTOM_OSP/$OSP_JKS
	cp /opt/netiq/idm/apps/configupdate/configupdate.sh.properties /config/osp/configupdate/configupdate.sh.properties
	cp $DEFAULT_TOMCAT/bin/setenv.sh $CUSTOM_TOMCAT/bin/setenv.sh
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
#ENDINGPOINT
