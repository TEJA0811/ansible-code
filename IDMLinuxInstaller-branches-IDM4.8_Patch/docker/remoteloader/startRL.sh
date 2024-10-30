#! /bin/bash

# variable pointing to rdxml configuration directory
RL_CONFIG_DIR=$1

RL_BINARY="rdxml"

if [ "$debug" == 'y' ]
then
	set -x
	DEBUGVAR="bash -x"
fi

echo "---------------------------------------------"
echo "Starting Remote Loader Service $(rpm --queryformat="%{VERSION}" -q novell-DXMLrdxmlx) ..."

##################################
#  Configure Driver Instance(s)  #
##################################
if [ ! -z "${RL_DRIVER_STARTUP}" ]
then

    RL_DRIVER_STARTUP="/config/rdxml/${RL_DRIVER_STARTUP}"
	
	if [ -f "${RL_DRIVER_STARTUP}" ]
	then
		readarray -t LINES < "${RL_DRIVER_STARTUP}"
		for LINE in "${LINES[@]}"
		do

			# Skip if line is empty or only contains spaces
			[ -z "$LINE" ] || [[ $LINE =~ ^\ +$ ]] && continue
			
			# Skip if line is commented
			[[ $LINE =~ ^[[:space:]]*\#.*$ ]] && continue
				
			cd "${RL_CONFIG_DIR}" && $RL_BINARY -config "${LINE}"
		done
		rm -f "${RL_DRIVER_STARTUP}" &> /dev/null
	fi
fi

#########################
#  Start Remote Loader  #
#########################
/etc/init.d/rdxml start

#####################################################
#  Redirect $LOGTOFOLLOW log output to docker logs  #
#####################################################
echo "Press CTRL+P,Q to detach from this container, if not detached already"
sleep 10s
LOGTOFOLLOWistrue=1
if [ ! -z "$LOGTOFOLLOW" ] && [ "$LOGTOFOLLOW" != "" ]
then
	ls $LOGTOFOLLOW &> /dev/null
	LOGTOFOLLOWistrue=$?
fi
if [ $LOGTOFOLLOWistrue -eq 0 ]
then
	tail -f $LOGTOFOLLOW
fi
tail -F /dev/null
