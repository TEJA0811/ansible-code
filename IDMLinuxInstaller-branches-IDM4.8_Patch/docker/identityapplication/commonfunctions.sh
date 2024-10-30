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
# userapp  host location
CONF_HOME="/config/userapp"
mkdir -p $CONF_HOME 
ORG_UA_REPLICA_COUNT=$UA_REPLICA_COUNT
if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
then
	while [ $UA_REPLICA_COUNT -gt 1 ]
	do
		if [ -f $CONF_HOME/controlling ]
		then
			controlnumber=$(cat $CONF_HOME/controlling)
			if [ -z $controlnumber ]
			then
				exitCodeforcontrol=1
			else
				grep -q $controlnumber /config/userapp/transaction-lock-file
				exitCodeforcontrol=$?
			fi
			if [ $exitCodeforcontrol -eq 0 ]
			then
				#skip and continue with next conf_home
				CONF_HOME="/config/userapp${UA_REPLICA_COUNT}"
				(( UA_REPLICA_COUNT-- ))
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
UA_REPLICA_COUNT=$ORG_UA_REPLICA_COUNT
if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
then
	#Create all the data layer's parent directory here
	while [ $UA_REPLICA_COUNT -gt 1 ]
	do
		#echo $UA_REPLICA_COUNT
		mkdir -p "/config/userapp${UA_REPLICA_COUNT}"
		(( UA_REPLICA_COUNT-- ))
	done
fi
UA_REPLICA_COUNT=$ORG_UA_REPLICA_COUNT
firstinstancenotcompleted=true
firstinstancerestnotcompleted=true
echo $fourteendigitnumber >> /config/userapp/transaction-lock-file
head -1 /config/userapp/transaction-lock-file | grep -q $fourteendigitnumber
entrymadefirst=$?
while [ true ]
do
	if [ "$firstinstancerestnotcompleted" == "false" ]
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
			if [ -f /idmpatch/common/scripts/common_install_vars.sh ]
			then
				source /idmpatch/common/scripts/common_install_vars.sh
			elif [ -f /idm/common/scripts/common_install_vars.sh ]
			then
				source /idm/common/scripts/common_install_vars.sh
			fi
			#wait till the first instance is configured
			#/config/userapp is the first instance data layer
			grep -q "Done building the Entitlement CODE MAP tables" /config/userapp/tomcat/logs/catalina.out &> /dev/null
			firstlogcheck=$?
			grep -q "org.apache.catalina.startup.Catalina.start Server startup" /config/userapp/tomcat/logs/catalina.out &> /dev/null
			secondlogcheck=$?
			if [ ${firstlogcheck} -ne 0 ] || [ ${secondlogcheck} -ne 0 ]
			then
				sleep 10s
				continue
			else
				firstinstancenotcompleted=false
				break
			fi
		done
		#Wait till rest call completes with first instance 
		whilecounter=1
		while [ $firstinstancerestnotcompleted ]
		do
			((whilecounter++))
			if [ "$whilecounter" == "10" ]
			then
				if [ ! -d /config/userapp2 ]
				then
					#Looks like rest call need not be enforced since this is not a kube setup
					firstinstancerestnotcompleted=false
					break
				fi
			fi
			#wait till the first instance is configured
			#/config/userapp is the first instance data layer
			if [ ! -f /config/userapp/restcallcompleted ]
			then
				sleep 10s
				continue
			else
				firstinstancerestnotcompleted=false
				break
			fi
		done

		## Need a variable to fetch the number of instances for userapp
		# Say the number is three for now ie., UA_REPLICA_COUNT=3
		#UA_REPLICA_COUNT=3
		if [ ! -z $UA_REPLICA_COUNT ] && [ $UA_REPLICA_COUNT -gt 1 ]
		then
			#Start the other instances but with their own unique data layer where possible
			CONF_HOME="/config/userapp${UA_REPLICA_COUNT}"
			(( UA_REPLICA_COUNT-- ))
			continue
		fi
	else
		#Adding the Controlling instance id with the unique random number
		echo $fourteendigitnumber > $CONF_HOME/controlling
		#For adding the unique workflow engine id
		uniqueengineid=${CONF_HOME#*/config/userapp}
		if [ -z $uniqueengineid ]
		then
			export UA_WORKFLOW_ENGINE_ID=ENGINE
		else
			export UA_WORKFLOW_ENGINE_ID=ENGINE${uniqueengineid}
		fi
	fi
	#Exit the loop at the end
	#Copying the configuration of first instance to all and editing the engine id to be unique
	if [ ${CONF_HOME} != "/config/userapp" ]
	then
		#Do it only once
		if [ ! -f ${CONF_HOME}/copiedfromfirstinstance ]
		then
			cp -rpf /config/userapp/{UserApplication,log,tomcat,version.properties} ${CONF_HOME}/
			#tomcat/conf will be linked from the first instance
			rm -rf ${CONF_HOME}/tomcat/conf /opt/netiq/idm/apps/tomcat/conf
			#Giving unique value for workflow engine id
			touch ${CONF_HOME}/copiedfromfirstinstance
		fi
		#Do it every time there is change in first instance
		#diff -q /config/userapp/tomcat/conf/ism-configuration.properties ${CONF_HOME}/tomcat/conf/ism-configuration.properties &> /dev/null
		#if [ $? -ne 0 ]
		#then
			#copy the first instance's ism-configuration.properties to destined instance
		#	cp -f /config/userapp/tomcat/conf/ism-configuration.properties ${CONF_HOME}/tomcat/conf/ism-configuration.properties
		#fi
	fi
	break
done
if [ ! -z ${UA_ADMIN} ]
then
	export UAADMIN_ATOMIC=$(awk -F'=|,' '{print $2}' <<< ${UA_ADMIN})
	if [ -z ${UAADMIN_ATOMIC} ]
	then
		export UAADMIN_ATOMIC=$(awk -F'=|.' '{print $2}' <<< ${UA_ADMIN})
	fi
fi
echo UA_REPLICA_COUNT=$ORG_UA_REPLICA_COUNT > /commonfunctions-sub.sh
echo CONF_HOME=$CONF_HOME >> /commonfunctions-sub.sh
echo UA_WORKFLOW_ENGINE_ID=$UA_WORKFLOW_ENGINE_ID >> /commonfunctions-sub.sh
echo UAADMIN_ATOMIC=$UAADMIN_ATOMIC >> /commonfunctions-sub.sh
#STARTINGPOINT
# variable pointing to userapp default location
DEFAULT_USERAPP="/opt/netiq/idm/apps/UserApplication"

#variable pointing to osp custom location
CUSTOM_USERAPP=$CONF_HOME/UserApplication

# variable pointing to tomcat default location
DEFAULT_TOMCAT="/opt/netiq/idm/apps/tomcat"

# variable pointing to tomcat custom location
CUSTOM_TOMCAT=$CONF_HOME/tomcat

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
	createBackLinkForFile $CUSTOM_USERAPP/logevent.conf $DEFAULT_USERAPP/logevent.conf
	createBackLinkForFile $CUSTOM_USERAPP/logging.properties $DEFAULT_USERAPP/logging.properties
	createBackLinkForFile $CUSTOM_USERAPP/master-key.txt $DEFAULT_USERAPP/master-key.txt
	createBackLinkForFile /config/userapp/configupdate/configupdate.sh.properties /opt/netiq/idm/apps/configupdate/configupdate.sh.properties
	createBackLinkForFile $CUSTOM_TOMCAT/bin/setenv.sh $DEFAULT_TOMCAT/bin/setenv.sh
}

CopyBackEditedFiles()
{
	cp $DEFAULT_USERAPP/logevent.conf $CUSTOM_USERAPP/logevent.conf
	cp $DEFAULT_USERAPP/logging.properties $CUSTOM_USERAPP/logging.properties
	cp $DEFAULT_USERAPP/master-key.txt $CUSTOM_USERAPP/master-key.txt
	cp /opt/netiq/idm/apps/configupdate/configupdate.sh.properties /config/userapp/configupdate/configupdate.sh.properties
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

