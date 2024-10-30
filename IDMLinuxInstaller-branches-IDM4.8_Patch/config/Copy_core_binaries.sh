#!/bin/bash

TOP_DIR=`pwd`
DRIVER_ROOT="$TOP_DIR/cd-image/IDM/packages/driver/"
ENGINE_ROOT="$TOP_DIR/cd-image/IDM/packages/engine/"
FANOUT_ROOT="$TOP_DIR/cd-image/IDM/packages/fanout/"
RL_ROOT="$TOP_DIR/cd-image/IDM/packages/rl/"
JAVA_RL_ROOT="$TOP_DIR/cd-image/IDM/packages/java_remoteloader/"
OPENSSL_ROOT="$TOP_DIR/cd-image/IDM/packages/OpenSSL/"
COMMON_ROOT="$TOP_DIR/cd-image/IDM/packages/common/"
COMMON64_ROOT="$TOP_DIR/cd-image/IDM/packages/common64/"
IDVAULT_ROOT="$TOP_DIR/cd-image/IDVault"
COMMON_RPMS_ROOT="$TOP_DIR/cd-image/common/packages"
###Removed iManager from 4.8.7
#IMANAGER_ROOT="$TOP_DIR/cd-image/iManager/packages"
#IMANAGER_PLUGIN_ROOT="$TOP_DIR/cd-image/iManager/plugins"
###Removed iManager from 4.8.7
SENTINEL_ROOT="$TOP_DIR/cd-image/SentinelLogManagementforIGA"
USERAPP_ROOT="$TOP_DIR/cd-image/user_application/packages"
REPORTING_ROOT="$TOP_DIR/cd-image/reporting/packages/"
SSPR_ROOT="$TOP_DIR/cd-image/sspr/packages"
OSP_ROOT="$TOP_DIR/cd-image/osp/packages"
ARTIFACTS="$TOP_DIR/artifacts"
LIB_ROOT="$TOP_DIR/cd-image/common/lib"
DESIGNER_ROOT="$TOP_DIR/cd-image/designer/packages"
IDM_ROOT="$TOP_DIR/cd-image/IDM/packages"
#ANALYZER_ROOT="$TOP_DIR/cd-image/analyzer/packages"
CLE_DIR="$TOP_DIR/cd-image/CLE"
IDMUTILITIES_ROOT="$TOP_DIR/cd-image/IDM"
EXCHANGESERVICE_ROOT="$TOP_DIR/cd-image/IDM/packages/AzureAD-ExchangeService"
PATCHCONFIGUTIL_LIB="$TOP_DIR/patchConfigUtil/lib"
#LIBSTDC_ROOT="$TOP_DIR/cd-image/IDM/packages/cpplibrary"
CEFPROCESSOR_ROOT="$TOP_DIR/cd-image/IDM/packages/cefprocessor"
IDCONSOLE_ROOT="$TOP_DIR/cd-image/idconsole"

######printf "\n*******************************Copy docker orchestration to the workarea******************************\n"
######printf "\n******************************************************************************************************\n"

cp -rpf $TOP_DIR/docker/orchestration $TOP_DIR/cd-image
rm -rf $TOP_DIR/cd-image/orchestration/kube/helm_package
rm -rf $TOP_DIR/cd-image/orchestration/docker-compose
 
printf "\n***********************************Copy Driver RPMS to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/netiq-DXMLarshim*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/netiq-DXMLRESTDrv*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/netiq-DXMLsentinel-REST*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/netiq-DXMLServiceNow*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLadeng*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLBanner*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLbasenoarch*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLbb*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDM_DCS_*/linux/novell-DXMLdcs*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLdelim*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLdev*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLebsCommon*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLebsHR*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLebsTCA*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLebsUM*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLedir*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLEdirDrv*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLengnnoarch*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLGoogleApps*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLGWRest*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLidprv*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLjdbc*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLjms*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLjntls*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLldap*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDM_MSGW_*/linux/novell-DXMLMSGway*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLmtask*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLnotes*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLnxset*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLpsoft*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLpxjob*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsapbl*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsaphrjco*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsappt*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsapus*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLSForce*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsoap*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLssop*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLtlmnt*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLtss*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLwkodr*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLRsrcProv*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLremedy75*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLnpum*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsch*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/netiq-DXMLRESTAzure*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLfanoutdriver*.rpm $DRIVER_ROOT 
cp -rpf $ARTIFACTS/IDM_UAD_*/Linux/netiq-DXMLuad*.rpm $DRIVER_ROOT
cp -rpf $ARTIFACTS/IDM_RRSD_*/linux/netiq-DXMLrrsd*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLIGIM*.rpm $DRIVER_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/netiq-DXMLedm*.rpm $DRIVER_ROOT

printf "\n***********************************Copy ENGINE RPMS to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLbasex*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLedir*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLengnnoarch*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLengnx*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLeventx*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLjntlsx*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLrdxmlx*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-NOVLjvmlx*.rpm $ENGINE_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLsch*.rpm $ENGINE_ROOT

printf "\n***********************************Copy FANOUT RPMS to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLfanoutagent*rpm $FANOUT_ROOT

printf "\n*************************************Copy RL RPMS to the workarea*************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLbase*.rpm $RL_ROOT/i586
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-DXMLrdxml*.rpm $RL_ROOT/i586
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/glibc-32bit*.rpm $RL_ROOT/i586
#cp -rpf $ARTIFACTS/eDir/eDirectory/setup/novell-edirectory-expat*.x86_64.rpm $RL_ROOT/i586
#cp -rpf $ARTIFACTS/eDir/eDirectory/setup/novell-edirectory-xdaslog-*.x86_64.rpm $RL_ROOT/i586
######cp -rpf $ARTIFACTS/eDir/eDirectory/setup/novell-edirectory-xdaslog-conf-*.noarch.rpm $RL_ROOT/i586
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-NOVLjvml*.rpm $RL_ROOT/i586
cp -rpf $ARTIFACTS/novell-edirectory-expat-32bit*.x86_64.rpm $RL_ROOT/i586
cp -rpf $ARTIFACTS/novell-edirectory-xdaslog-32bit-*.x86_64.rpm $RL_ROOT/i586
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLrdxmlx*.rpm $RL_ROOT/x86_64

printf "\n*********************************Copy IDMCEFProcessor to the workarea*********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-IDMCEFProcessorx*.rpm $CEFPROCESSOR_ROOT/x86_64
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/novell-IDMCEFProcessor*.rpm $CEFPROCESSOR_ROOT/i386
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/noarch/novell-IDMCEFProcessorCommon*.rpm $CEFPROCESSOR_ROOT/noarch

printf "\n*********************************Copy Java RemoteLoader to the workarea*******************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IDMFramework/cd-image/java_remoteloader/dirxml_jremote.tar.gz $JAVA_RL_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/java_remoteloader/dirxml_jremote_mvs.tar $JAVA_RL_ROOT
######cp -rpf $ARTIFACTS/IDMFramework/cd-image/java_remoteloader/dirxml_jremote_dev.tar.gz $JAVA_RL_ROOT

printf "\n***********************************Copy OpenSSL RPMS to the workarea**********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/edir_sdk/components/edir_rpms/release/netiq-openssl-32bit-*.x86_64.rpm $OPENSSL_ROOT/i586
cp -rpf $ARTIFACTS/eDir/eDirectory/setup/netiq-openssl-[1-9].*.x86_64.rpm $OPENSSL_ROOT/x86_64

printf "\n***********************************Copy Common RPMS to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/eDir/eDirectory/setup/novell-edirectory-xdaslog-conf-*.noarch.rpm $COMMON_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/netiq-zoomdb*.rpm $COMMON_ROOT

printf "\n***********************************Copy Common64 RPMS to the workarea*********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-DXMLbasex*.rpm $COMMON64_ROOT
cp -rpf $ARTIFACTS/eDir/eDirectory/setup/novell-edirectory-expat*.x86_64.rpm $COMMON64_ROOT
cp -rpf $ARTIFACTS/edir_sdk/components/CEFInstrument_sdk/lib/Linux/x86_64/release/novell-edirectory-cefinstrument-*.x86_64.rpm $COMMON64_ROOT
cp -rpf $ARTIFACTS/edir_sdk/components/xdas_sdk/lib/Linux/x86_64/release/novell-edirectory-xdaslog.x86_64.rpm $COMMON64_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/linux/setup/packages/x86_64/novell-NOVLjvmlx*.rpm $COMMON64_ROOT

printf "\n***********************************Copy eDir Build to the workarea************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/eDir/eDirectory/* $IDVAULT_ROOT
cp -rpf $ARTIFACTS/eDir_NonRoot.tar.gz $IDVAULT_ROOT

printf "\n****************************Copy Common Framework RPMS Build to the workarea**************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/netiq-jre-*.rpm $COMMON_RPMS_ROOT/java
cp -rpf $ARTIFACTS/netiq-jrex-*.rpm $COMMON_RPMS_ROOT/java

cp -rpf $ARTIFACTS/netiq-idmtomcat*.rpm $COMMON_RPMS_ROOT/tomcat
cp -rpf $ARTIFACTS/netiq-activemq*.rpm $COMMON_RPMS_ROOT/activemq
cp -rpf $ARTIFACTS/netiq-postgresql*.rpm $COMMON_RPMS_ROOT/postgres
cp -rpf $ARTIFACTS/final/netiq-tomcatconfig*.rpm $COMMON_RPMS_ROOT/tomcat
cp -rpf $ARTIFACTS/netiq-tomcat*.rpm $COMMON_RPMS_ROOT/tomcat
cp -rpf $ARTIFACTS/netiq-nginx-*.x86_64.rpm $COMMON_RPMS_ROOT/nginx

###Removed iManager from 4.8.7
#printf "\n****************************Copy iManager Build to the workarea***************************************\n"
#printf "\n******************************************************************************************************\n"

#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/edir/rpms/netiq-openssl-*.x86_64.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/edir/rpms/nici64-*.x86_64.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/base/rpms/novell-base-*.x86_64.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/imanager/rpms/novell-imanager-*.noarch.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/edir/rpms/novell-libstdc++6*.x86_64.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/imanager/rpms/novell-plugin-base-*.noarch.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/tomcat/rpms/novell-tomcat9-*.noarch.rpm $IMANAGER_ROOT
#cp -rpf $ARTIFACTS/iManager/installs/linux/packages/tomcat/rpms/novell-tomcat9-webapps-*.noarch.rpm $IMANAGER_ROOT

#cp -rpf $ARTIFACTS/iManager/installs/linux $IMANAGER_ROOT

#printf "\n****************************Copy iManager Plugins to the workarea*************************************\n"
#printf "\n******************************************************************************************************\n"
#
#cp -rpf $ARTIFACTS/IDMPlugins_IMAN_*.npm $IMANAGER_PLUGIN_ROOT
######cp -rpf $ARTIFACTS/PwdManagementPlugins_IMAN_*.npm $IMANAGER_PLUGIN_ROOT
######cp -rpf $ARTIFACTS/eDir_IMANPlugins.npm	$IMANAGER_PLUGIN_ROOT
######cp -rpf $ARTIFACTS/pki.npm $IMANAGER_PLUGIN_ROOT
######cp -rpf $ARTIFACTS/nmas.npm $IMANAGER_PLUGIN_ROOT
###Removed iManager from 4.8.7

printf "\n****************************Copy UserAPP Core Build to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/netiq-configupdate*.rpm $COMMON_RPMS_ROOT/config_update
cp -rpf $ARTIFACTS/netiq-userapputils*.rpm $USERAPP_ROOT/ua
cp -rpf $ARTIFACTS/netiq-userapp*.rpm $USERAPP_ROOT/ua

printf "\n****************************Copy iga formrenderer Build to the workarea*******************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/netiq-forms-*.noarch.rpm $USERAPP_ROOT/ua

printf "\n****************************Copy iga workflow Build to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/netiq-workflow-*.noarch.rpm $USERAPP_ROOT/ua

printf "\n****************************Copy Reporting Build to the workarea**************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/Reporting_IDMDCS/linux/netiq-IDMDCS-*.noarch.rpm $REPORTING_ROOT
cp -rpf $ARTIFACTS/Reporting_IDMDCS/linux/netiq-IDMRPT-*.noarch.rpm	$REPORTING_ROOT
cp -rpf $ARTIFACTS/Reporting_IDMDCS/linux/netiq-RPTcommon-*.noarch.rpm $REPORTING_ROOT
cp -rpf $ARTIFACTS/IDM_Reports.zip $REPORTING_ROOT

printf "\n*******************************Copy SSPR Build to the workarea****************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/sspr-*/Linux/netiq-sspr.rpm $SSPR_ROOT
cp -rpf $ARTIFACTS/sspr-*/Linux/netiq-ssprconfig.rpm $SSPR_ROOT

printf "\n*******************************Copy OSP Build to the workarea*****************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/osp-*/Linux/netiq-osp.rpm $OSP_ROOT
cp -rpf $ARTIFACTS/config-util-*.jar $OSP_ROOT/../lib/netiq-configutil.jar

printf "\n*****************************Copy common java utils to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

#cp -rpf $ARTIFACTS/dist/lib/idm_install_utils.jar $COMMON_RPMS_ROOT/utils
cp -rpf $ARTIFACTS/dist/lib/idm_install_utils.jar $COMMON_RPMS_ROOT/utils
cp -rpf $ARTIFACTS/3rdParty_Jars/jdom.jar $LIB_ROOT
cp -rpf $ARTIFACTS/3rdParty_Jars/jaxen-1.1.1.jar $LIB_ROOT
cp -rpf $ARTIFACTS/3rdParty_Jars/saxpath.jar $LIB_ROOT
cp -rpf $ARTIFACTS/3rdParty_Jars/xp-*.jar $LIB_ROOT
cp -rpf $ARTIFACTS/edir_sdk/novell-jldap-devel-xplat/lib/ldap.jar $LIB_ROOT
cp -rpf $ARTIFACTS/edir_sdk/components/edir_java/jclient.jar $LIB_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/windows/setup/remoteloader/lib/nxsl.jar $LIB_ROOT
cp -rpf $ARTIFACTS/IDMFramework/cd-image/windows/setup/engine9/lib/dirxml_misc.jar $LIB_ROOT

######printf "\n*****************************Copy Light Weight Designer to the workarea*******************************\n"
######printf "\n******************************************************************************************************\n"

######cp -rpf $ARTIFACTS/designer_install/lightWeightDesigner-linux.gtk.x86_64.zip $DESIGNER_ROOT

printf "\n********************************Copy JLogger rpm to the workarea**************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/novell-jlogger.rpm $FANOUT_ROOT

######printf "\n***********************************Copy DirXML Changelog to the workarea******************************\n"
######printf "\n******************************************************************************************************\n"

######cp -rpf $ARTIFACTS/IDMFramework/cd-image/Dirxml-Changelog/ $IDM_ROOT

######printf "\n***********************************Copy Oracle EBS Scripts to the workarea****************************\n"
######printf "\n******************************************************************************************************\n"

######cp -rpf $ARTIFACTS/IDMFramework/cd-image/scripts/ $IDM_ROOT

######printf "\n****************************Get the CLE Windows Framework binaries *************************************\n"
######printf "\n********************************************************************************************************\n"

######cp -rpf "$ARTIFACTS/CLE"*"/"*"" $CLE_DIR/

######printf "\n***********************************Copy Utilities to the workarea*************************************\n"
######printf "\n******************************************************************************************************\n"

######cp -rpf $ARTIFACTS/IDMFramework/cd-image/windows/setup/utilities/ $IDMUTILITIES_ROOT

######printf "\n***********************************Copy AzureAD-ExchangeService to the workarea***********************\n"
######printf "\n******************************************************************************************************\n"

######cp -rpf $ARTIFACTS/IDMFramework/cd-image/windows/setup/drivers/azuread/ExchangeService/* $EXCHANGESERVICE_ROOT

#printf "\n*****************************Copy libstdc rpm  to the workarea****************************************\n"
#printf "\n******************************************************************************************************\n"
#Not required from IDM 4.8.7
#cp -rpf $ARTIFACTS/edir_sdk/components/edir_rpms/release/novell-libstdc++6-5*.x86_64.rpm $LIBSTDC_ROOT/x86_64
#cp -rpf $ARTIFACTS/edir_sdk/components/edir_rpms/release/novell-libstdc++6-32bit-5*.x86_64.rpm $LIBSTDC_ROOT/i586

printf "\n*****************************Copy IdentityAppsTools  to the workarea**********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/MigrationSettings.zip $TOP_DIR/cd-image/user_application/IDM_Tools 
#cp -rpf $ARTIFACTS/WorkflowMigrationAPI.zip $TOP_DIR/cd-image/user_application/IDM_Tools
#cp -rpf $ARTIFACTS/WorkflowMigration.zip $TOP_DIR/cd-image/user_application/IDM_Tools

#printf "\n*****************************Copy patchConfigUtil  to the workarea************************************\n"
#printf "\n******************************************************************************************************\n"

#cp -rpf $ARTIFACTS/patchConfigUtil.jar $COMMON_RPMS_ROOT/utils
#cp -rpf $PATCHCONFIGUTIL_LIB/*.jar $COMMON_RPMS_ROOT/utils

printf "\n*******************************Copy IDConsole build to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/IdentityConsole_*_Linux/* $IDCONSOLE_ROOT

printf "\n*******************************Copy RPM validation Public Key to the workarea*************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/MicroFocusGPGPackageSign.pub $TOP_DIR/cd-image/common/license/

#Removed from IDM 4.8.8
#printf "\n*******************************Copy activemq 5.16.6 jar for JRE8 to the workarea**********************\n"
#printf "\n******************************************************************************************************\n"

#cp -rpf $ARTIFACTS/activemq-all-5.16.6.jar $COMMON_RPMS_ROOT/activemq
