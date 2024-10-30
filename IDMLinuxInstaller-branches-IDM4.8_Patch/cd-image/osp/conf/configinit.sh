#! /bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

app_home="/opt/netiq/idm/apps/osp"
java_home="/opt/netiq/common/jre"

"$java_home/bin/java" -Dlog4j.configuration="file:///$app_home/conf/log4j-config.xml" -Dcom.netiq.ism.config="$app_home/conf/idmapps-configuration.properties" -jar "${app_home}/lib/netiq-configutil.jar" -useDb false -script "$1"
