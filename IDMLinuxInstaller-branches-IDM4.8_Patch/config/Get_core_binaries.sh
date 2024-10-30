#!/bin/bash

TOP_DIR=`pwd`
ARTIFACTS_DIR="$TOP_DIR/artifacts"

cd $ARTIFACTS_DIR

printf "\n****************************Get the xdaslog_Linux Binaries to the workarea****************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-jenkins3.labs.blr.novell.com:8080/job/XDASEventLog-linux32_x64_920_Patches/lastSuccessfulBuild/artifact/RPMS/x86_64/novell-edirectory-xdaslog-32bit-9.2.8.0000-0.x86_64.rpm

printf "\n****************************Get the expat_linux Binaries to the workarea******************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-jenkins3.labs.blr.novell.com:8080/job/expat-linux32_x64_920_Patches/lastSuccessfulBuild/artifact/RPMS/x86_64/novell-edirectory-expat-32bit.x86_64.rpm

###Removed iManager from 4.8.7
#printf "\n****************************Get the iManager linux Binaries to the workarea***************************\n"
#printf "\n******************************************************************************************************\n"

#wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/iManager/326_P3_FCS/iMan_326_P3_linux_x86_64.tgz
#tar -zxf iMan_326_P3_linux_x86_64.tgz
#rm -rf iMan_326_P3_linux_x86_64.tgz

#printf "\n****************************Get the iManager Plugin Binaries to the workarea***************************\n"
#printf "\n******************************************************************************************************\n"

#wget -q http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDMPlugins/job/IDM4.8_Patch/job/DirXML27_plugins_npm/lastSuccessfulBuild/artifact/IDMPlugins_IMAN_3_2_IDM_4_8_5_0100.npm
#wget -q http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDMPlugins/job/IDM4.8_Patch/job/PwdManagement27_plugins_npm/lastSuccessfulBuild/artifact/PwdManagementPlugins_IMAN_3_2.npm
#wget -q http://blr-builder.labs.blr.novell.com/artifacts/Publish/eDir/926_FCS/plugins/eDir_IMANPlugins.npm
#wget -q http://blr-builder.labs.blr.novell.com/artifacts/Publish/eDir/926_FCS/plugins/nmas.npm
#wget -q http://blr-builder.labs.blr.novell.com/artifacts/Publish/eDir/926_FCS/plugins/pki.npm
###Removed iManager from 4.8.7

printf "\n*****************************Get the UserAPP Core Binaries to the workarea****************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/idmua-installer_4.8.0_Patch/lastSuccessfulBuild/artifact/netiq-configupdate/target/rpm/netiq-configupdate/RPMS/noarch/netiq-configupdate-5.0.0-0.noarch.rpm	
wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/idmua-installer_4.8.0_Patch/lastSuccessfulBuild/artifact/netiq-userapp/target/rpm/netiq-userapp/RPMS/noarch/netiq-userapp-4.8.8-0.noarch.rpm
wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/idmua-installer_4.8.0_Patch/lastSuccessfulBuild/artifact/netiq-userapputils/target/rpm/netiq-userapputils/RPMS/noarch/netiq-userapputils-4.8.8-0.noarch.rpm

printf "\n**********************************Get the OSP Binaries to the workarea********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/IDM/OSP/osp-6.7.0.zip
unzip -q osp-6.7.0.zip
rm -rf osp-6.7.0.zip

printf "\n**********************************Get the SSPR Binaries to the workarea*******************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/IDM/SSPR/sspr-4.7.0.0.zip
unzip -q sspr-4.7.0.0.zip
rm -rf sspr-4.7.0.0.zip

printf "\n*****************************Get the iga formrenderer Binaries to the workarea************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/igaformrenderer_4.8.0_Patch/lastSuccessfulBuild/artifact/distribution/target/rpm/netiq-forms/RPMS/noarch/netiq-forms-1.0.7-1.noarch.rpm

printf "\n*****************************Get the iga workflow Binaries to the workarea****************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/iga-workflow_4.8.0_Patch/lastSuccessfulBuild/artifact/target/rpm/netiq-workflow/RPMS/noarch/netiq-workflow-1.8.0-1.noarch.rpm
 
printf "\n*****************************Get the Reporting Binaries to the workarea*******************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/Reporting_IDMDCS_4.8.0_Patch_Pipeline/lastSuccessfulBuild/artifact/Reporting_IDMDCS.zip
unzip -q Reporting_IDMDCS.zip
rm -rf Reporting_IDMDCS.zip
wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/IDM_Reports_4.8.0_Patch/lastSuccessfulBuild/artifact/build/IDM_Reports.zip

printf "\n*****************************Get the Common Components Binaries to the workarea***********************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/tomcat/9.0.76/netiq-tomcat-9.0.76.0-1.noarch.rpm
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/tomcat/9.0.76/netiq-idmtomcat-9.0.76.0-1.noarch.rpm
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Postgres/12.15.0/netiq-postgresql-12.15-1.noarch.rpm
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/activemq/5.18.2/netiq-activemq-5.18.2-1.noarch.rpm
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/nginx/1.24.0/netiq-nginx-1.24.0-1.x86_64.rpm

printf "\n****************************Get the jlogger  Binaries to the workarea*********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/jlogger_4.8.0/lastSuccessfulBuild/artifact/final/novell-jlogger.rpm

printf "\n****************************Get the eDir 910 linux Binaries to the workarea***************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/eDir/929_FCS/linux/eDirectory_929_Linux_x86_64.tar.gz
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/eDir/929_FCS/linux/eDirectory_929_Linux_x86_64_NonRoot.tar.gz
mkdir -p eDir
tar -zxf eDirectory_929_Linux_x86_64.tar.gz -C eDir

mv eDirectory_929_Linux_x86_64_NonRoot.tar.gz eDir_NonRoot.tar.gz

printf "\n****************************Get the eDir sdk Binaries to the workarea*********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/eDir/929_FCS/edir_sdk/edir_sdk_idmdelivery.zip
unzip -q edir_sdk_idmdelivery.zip
rm -rf edir_sdk_idmdelivery.zip

printf "\n****************************Get the ntls-linux32_910 Binaries to the workarea*************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-jenkins3.labs.blr.novell.com:8080/job/ntls-linux32_920_Patches/lastSuccessfulBuild/artifact/ntls-linux32.zip
unzip -q -o ntls-linux32.zip
rm -rf ntls-linux32.zip

printf "\n****************************Get the CLE Windows build to the workare**********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-builder.labs.blr.novell.com/artifacts/CLE/4.4.0.0/CLE_4.4_11.zip
unzip -q CLE_4.4_11.zip

printf "\n***********************************Get JRE package  to the workarea**********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/jdk/openjdk/azul/jdk11.64.19/netiq-jrex-11.64.19-1.x86_64.rpm
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/jdk/openjdk/azul/jdk11.64.19/netiq-jre-11.64.19-1.i586.rpm

printf "\n****************************Get the config-util jar to the workare************************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/IDM/OSP/config-util/1.7.1/config-util-1.7.1-384-uber.jar

printf "\n****************************Get the IdentityAppsTools to the workare**********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/IdentityAppsTools_1.0.0_Patch/lastSuccessfulBuild/artifact/ClientSettingsMigration/target/MigrationSettings.zip
wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/IdentityAppsTools_1.0.0_Patch/lastSuccessfulBuild/artifact/WorkflowMigrationAPITool/target/WorkflowMigrationAPI.zip
wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/IdentityAppsTools_1.0.0_Patch/lastSuccessfulBuild/artifact/WorkflowMigrationTool/target/WorkflowMigration.zip

printf "\n****************************Get the Identity Console to the workarea**********************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/Identity_Console/1.7.1_FCS/standalone_build/IdentityConsole_171_Linux.tar.gz
tar -zxf IdentityConsole_171_Linux.tar.gz
rm -rf IdentityConsole_171_Linux.tar.gz

printf "\n****************************Get the RPM validation Public Key to the workarea*************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-builder.labs.blr.novell.com/artifacts/MFSign/Public_Key/MicroFocusGPGPackageSign.pub

#Removed from IDM 4.8.8
#printf "\n*****************************Get the activemq 5.16.6 for JRE8 support to the workarea*****************\n"
#printf "\n******************************************************************************************************\n"

#wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/activemq/5.16.6/activemq-all-5.16.6.jar
