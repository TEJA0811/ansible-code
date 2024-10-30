#!/bin/bash

TOP_DIR=`pwd`

printf "\n****************************Get the Product binaries to the workarea**********************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $TOP_DIR/cd-image $TOP_DIR/cd-image_RL

printf "\n***********************Remove the unwanted binaries from the workarea*********************************\n"
printf "\n******************************************************************************************************\n"

cd $TOP_DIR/cd-image_RL

rm -rf  CLE IDVault activemq configure.sh custom_context_sample.ldif designer iManager orchestration osp reporting sspr user_application SentinelLogManagementforIGA
rm -rf $TOP_DIR/cd-image_RL/IDM/packages/engine/
rm -rf $TOP_DIR/cd-image_RL/IDM/packages/fanout/
rm -rf $TOP_DIR/cd-image_RL/common/packages/activemq
rm -rf $TOP_DIR/cd-image_RL/common/packages/config_update
rm -rf $TOP_DIR/cd-image_RL/common/packages/nginx
rm -rf $TOP_DIR/cd-image_RL/common/packages/postgres
rm -rf $TOP_DIR/cd-image_RL/common/packages/tomcat
rm -rf $TOP_DIR/cd-image_RL/common/packages/ldap_utils
rm -rf $TOP_DIR/cd-image_RL/common/packages/utils
rm -rf $TOP_DIR/cd-image_RL/common/lib
rm -rf $TOP_DIR/cd-image_RL/IDM/ldif

printf "\n***************************** Creating RL ISO Images **************************************************\n"

cd $TOP_DIR

mkisofs -iso-level 4 -l -J -r -A "Remote Loader 4.8.4 - Linux" -V "IDM4.8.4_RL" -p "NOVELL Inc." -publisher "Novell Inc." -copyright copy.txt -hide-rr-moved -o Identity_Manager_4.8.4_RL_Linux.iso cd-image_RL/ &

wait

printf "\n*********Calculating MD5sum's & sha256sum of the ISO's*****************************************************************\n"

md5sum Identity_Manager_4.8.4_RL_Linux.iso > Identity_Manager_4.8.4_RL_Linux.iso.md5 &
sha256sum Identity_Manager_4.8.4_RL_Linux.iso > Identity_Manager_4.8.4_RL_Linux.iso.sha256sum &

wait # Wait for creation of md5 files to complete.

printf "\n**************************************************Done!!!!!!***********************************************************\n"
