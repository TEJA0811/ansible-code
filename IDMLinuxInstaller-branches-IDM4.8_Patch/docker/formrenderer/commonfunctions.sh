#variable pointing to osp custom location
CUSTOM_FORMSRENDERER="/config/FormRenderer"

#function to create back links for files
createBackLinkForFile() {
        SOURCE_FILE=$1 # first file
        DEST_FILE=$2 # second file

	if [ -e $SOURCE_FILE ] ; then
		# rm if destination file exists
		if [ -e $DEST_FILE ] ; then 
			rm $DEST_FILE &> /dev/null
		fi
        ln -s $SOURCE_FILE $DEST_FILE
	fi
}

createBackLinkFiles()
{
	createBackLinkForFile $CUSTOM_FORMSRENDERER/netiq-golang.sh /etc/init.d/netiq-golang.sh
	createBackLinkForFile $CUSTOM_FORMSRENDERER/ServiceRegistry.json /opt/netiq/idm/apps/sites/ServiceRegistry.json
	createBackLinkForFile $CUSTOM_FORMSRENDERER/config.ini /opt/netiq/idm/apps/sites/config.ini
	createBackLinkForFile $CUSTOM_FORMSRENDERER/nginx.conf /opt/netiq/common/nginx/nginx.conf
}

CopyBackEditedFiles()
{
	cp /etc/init.d/netiq-golang.sh $CUSTOM_FORMSRENDERER/netiq-golang.sh
	cp /opt/netiq/idm/apps/sites/ServiceRegistry.json $CUSTOM_FORMSRENDERER/ServiceRegistry.json
	cp /opt/netiq/idm/apps/sites/config.ini $CUSTOM_FORMSRENDERER/config.ini
	cp /opt/netiq/common/nginx/nginx.conf $CUSTOM_FORMSRENDERER/nginx.conf
}

