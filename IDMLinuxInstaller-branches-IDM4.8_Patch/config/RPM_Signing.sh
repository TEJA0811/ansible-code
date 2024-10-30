#!/bin/bash

printf "\n************************************Copy original RPMS to be signed*************************************\n"
printf "\n******************************************************************************************************\n"

mkdir $WORKSPACE/rpms_4signing

cp --parents cd-image/IDM/packages/cefprocessor/i386/novell-IDMCEFProcessor-*.i586.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/cefprocessor/noarch/novell-IDMCEFProcessorCommon-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/cefprocessor/x86_64/novell-IDMCEFProcessorx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/common/netiq-zoomdb-*.i386.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/common64/novell-NOVLjvmlx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/driver/novell-DXMLbasenoarch-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/driver/novell-DXMLedir-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/driver/novell-DXMLpxjob-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/driver/novell-DXMLRsrcProv-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/driver/novell-DXMLfanoutdriver-*.noarch.rpm $WORKSPACE/rpms_4signing
#cp --parents cd-image/IDM/packages/driver/netiq-DXMLuad-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLedir-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLengnnoarch-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLengnx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLeventx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLsch-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/fanout/novell-DXMLfanoutagent-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/fanout/novell-jlogger-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/rl/i586/novell-DXMLrdxml-*.i586.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/rl/i586/novell-NOVLjvml-*.i586.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/rl/x86_64/novell-DXMLrdxmlx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/activemq/netiq-activemq-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/config_update/netiq-configupdate-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/java/netiq-jre-*.i586.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/java/netiq-jrex-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/nginx/netiq-nginx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/postgres/netiq-postgresql-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/tomcat/netiq-idmtomcat-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/tomcat/netiq-tomcatconfig-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/common/packages/tomcat/netiq-tomcat-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/osp/packages/netiq-osp-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/reporting/packages/netiq-IDMDCS-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/reporting/packages/netiq-IDMRPT-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/reporting/packages/netiq-RPTcommon-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/sspr/packages/netiq-sspr-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/sspr/packages/netiq-ssprconfig-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/user_application/packages/ua/netiq-userapputils-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/user_application/packages/ua/netiq-userapp-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/user_application/packages/ua/netiq-forms-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/user_application/packages/ua/netiq-workflow-*.noarch.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLbasex-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLjntlsx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-DXMLrdxmlx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/engine/novell-NOVLjvmlx-*.x86_64.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/driver/novell-DXMLjntls-*.i586.rpm $WORKSPACE/rpms_4signing
cp --parents cd-image/IDM/packages/rl/i586/novell-DXMLbase-*.i586.rpm $WORKSPACE/rpms_4signing 
cp --parents cd-image/IDM/packages/common64/novell-DXMLbasex-*.x86_64.rpm $WORKSPACE/rpms_4signing

printf "\n************************************Remove RPM from source location***********************************\n"
printf "\n******************************************************************************************************\n"

rm -rf $WORKSPACE/cd-image/IDM/packages/cefprocessor/i386/novell-IDMCEFProcessor-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/cefprocessor/noarch/novell-IDMCEFProcessorCommon-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/cefprocessor/x86_64/novell-IDMCEFProcessorx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/common/netiq-zoomdb-*.i386.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/common64/novell-NOVLjvmlx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLbasenoarch-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLedir-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLpxjob-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLRsrcProv-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLfanoutdriver-*.noarch.rpm
#rm -rf $WORKSPACE/cd-image/IDM/packages/driver/netiq-DXMLuad-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLedir-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLengnnoarch-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLengnx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLeventx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLsch-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/fanout/novell-DXMLfanoutagent-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/fanout/novell-jlogger-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-DXMLrdxml-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-NOVLjvml-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/x86_64/novell-DXMLrdxmlx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/common/packages/activemq/netiq-activemq-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/common/packages/config_update/netiq-configupdate-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/common/packages/java/netiq-jre-*.i586.rpm
rm -rf $WORKSPACE/cd-image/common/packages/java/netiq-jrex-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/common/packages/nginx/netiq-nginx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/common/packages/postgres/netiq-postgresql-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/common/packages/tomcat/netiq-idmtomcat-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/common/packages/tomcat/netiq-tomcatconfig-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/common/packages/tomcat/netiq-tomcat-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/osp/packages/netiq-osp-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/reporting/packages/netiq-IDMDCS-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/reporting/packages/netiq-IDMRPT-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/reporting/packages/netiq-RPTcommon-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/sspr/packages/netiq-sspr-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/sspr/packages/netiq-ssprconfig-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/user_application/packages/ua/netiq-userapputils-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/user_application/packages/ua/netiq-userapp-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/user_application/packages/ua/netiq-forms-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/user_application/packages/ua/netiq-workflow-*.noarch.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLbasex-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLjntlsx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-DXMLrdxmlx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/engine/novell-NOVLjvmlx-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLjntls-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-DXMLbase-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/common64/novell-DXMLbasex-*.x86_64.rpm

printf "\n************************************Rpm Signing on Signing server*************************************\n"
printf "\n******************************************************************************************************\n"

ssh mfsign@prvbldiam01.iam.nqbuild.lab "mkdir IDM_RPM_SIGNING"
scp -r $WORKSPACE/rpms_4signing mfsign@prvbldiam01.iam.nqbuild.lab:~/IDM_RPM_SIGNING
ssh mfsign@prvbldiam01.iam.nqbuild.lab "java -Dmfsignconfig=/home/mfsign/buildcert/mfsign.config -jar /home/mfsign/buildcert/mfsign.jar ~/IDM_RPM_SIGNING/rpms_4signing"
ssh mfsign@prvbldiam01.iam.nqbuild.lab "cp -rpf ~/IDM_RPM_SIGNING/rpms_4signing ~/IDM_RPM_SIGNING/rpms_signed"
scp -r mfsign@prvbldiam01.iam.nqbuild.lab:~/IDM_RPM_SIGNING/rpms_signed $WORKSPACE/
ssh mfsign@prvbldiam01.iam.nqbuild.lab "rm -rf IDM_RPM_SIGNING"

printf "\n*******************************Copy Signed RPM to the workarea****************************************\n"
printf "\n******************************************************************************************************\n"

cd $WORKSPACE/rpms_signed/cd-image
cp --parents -vrpf `find -name \*.rpm` $WORKSPACE/cd-image
cd $WORKSPACE
