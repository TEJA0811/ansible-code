#!/bin/bash

TOP_DIR=`pwd`
ARTIFACTS_DIR="$TOP_DIR/artifacts"

cd $ARTIFACTS_DIR

printf "\n*****************************Get the UserAPP Drivers Binaries to the workarea*************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDMDrivers/job/ComposerDriverShim/lastSuccessfulBuild/artifact/IDM_UAD_487.zip
unzip -q IDM_UAD_*.zip
rm -rf IDM_UAD_*.zip

printf "\n*****************************Get the RRSD Drivers Binaries to the workarea****************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://userapp-jenkins.labs.blr.novell.com:8080/job/RRSD_IDM4.8_Patch/lastSuccessfulBuild/artifact/IDM_RRSD_4870.zip
unzip -q IDM_RRSD_*.zip
rm -rf IDM_RRSD_*.zip

printf "\n*****************************Get the Report Drivers Binaries to the workarea**************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/Engine/job/Report_Driver_master/lastSuccessfulBuild/artifact/IDM_DCS_4.2.1_P4.zip
unzip -q IDM_DCS_*.zip
rm -rf IDM_DCS_*.zip

printf "\n*****************************Get the Report Drivers Binaries to the workarea**************************\n"
printf "\n******************************************************************************************************\n"

wget -q http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM_Trunk/job/IDMDrivers/job/MSGatewayDriver_trunk/lastSuccessfulBuild/artifact/IDM_MSGW_4.2.2_P5.zip
unzip -q IDM_MSGW_*.zip
rm -rf IDM_MSGW_*.zip

