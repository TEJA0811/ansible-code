FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ARG BUILD_ID
RUN zypper ref -s \
        && zypper -n in wget vim gettext gettext-tools net-tools p7zip-full bc iproute2 ncurses-utils curl docker python310 \
	&& python3.10 -m venv $VIRTUAL_ENV \
	&& python -m pip install azure-cli \
        && mkdir /idm \
        && wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/IDM4.8_Patch_Pipeline/job/IDMLinuxInstaller_IDM4.8_Patch/$BUILD_ID/artifact/Identity_Manager_4.8.8_Linux.iso -P /idm \
        && 7z x /idm/Identity_Manager_4.8.8_Linux.iso -o/idm \
        && mkdir /azure \
        && wget --no-check-certificate https://blr-idm-jenkins.labs.blr.novell.com:8443/job/IDM4.8_Patch/job/Engine/job/IDM_docker_Tools_IDM4.8_Patch/lastSuccessfulBuild/artifact/azure.zip -P /azure/ \
        && 7z e /azure/azure.zip -o/azure/ \
        && 7z x /azure/IDM_4.8.7_Azure_Terraform_Configuration.zip -o/azure/ \
        && cp -rf /azure/terraform.tfvars /azure/IDM_Azure_Terraform_Configuration/ \
        && cp -rf /azure/azure_pg.tf /azure/IDM_Azure_Terraform_Configuration/ \
        && wget --no-check-certificate https://blr-idm-jenkins.labs.blr.novell.com:8443/job/IDM4.8_Patch/job/Engine/job/IDM_docker_Tools_IDM4.8_Patch/lastSuccessfulBuild/artifact/kubernetes.zip -P /azure/ \
        && 7z x /azure/kubernetes.zip -o/azure/ \
        &&  cp -r /azure/kubernetes/helm_charts /azure/IDM_Azure_Terraform_Configuration/ \
        && cp /azure/kubernetes/values.yaml /azure/IDM_Azure_Terraform_Configuration/ \
        && cp /azure/kubernetes/data_containers.ldif /azure/IDM_Azure_Terraform_Configuration/ \
        && rm -r /azure/*.zip /azure/kubernetes /azure/terraform.tfvars /azure/azure \
        && rpm -ihv /idm/common/packages/java/netiq-jrex-*.rpm \
        && zypper -n rm wget \
        && zypper cc -a \
        && rm -rf /idm/CLE /idm/RHEL-Prerequisite.sh /idm/configure.sh /idm/install.sh /idm/uninstall.sh /idm/designer /idm/ReleaseNotes \
        && rm -rf /idm/common/bin /idm/common/license /idm/common/locale /idm/common/lib  \
        && rm -rf /idm/common/packages/activemq /idm/common/packages/config_update /idm/common/packages/ldap_utils /idm/common/packages/nginx /idm/common/packages/postgres /idm/common/packages/tomcat /idm/common/packages/java \
        && cd /idm \
        && mkdir -p /idm/backup \
        && cp IDVault/scripts/prompts.sh backup/;rm -rf IDVault/*; mkdir -p IDVault/scripts;mv  backup/* IDVault/scripts \
        && cp IDM/scripts/prompts.sh backup/;rm -rf IDM/*; mkdir -p IDM/scripts;mv  backup/* IDM/scripts \ 
        && cp activemq/scripts/prompts.sh backup/;rm -rf activemq/*; mkdir -p activemq/scripts;mv  backup/* activemq/scripts \
        && cp osp/scripts/prompts.sh backup/;rm -rf osp/*; mkdir -p osp/scripts;mv  backup/* osp/scripts \
        && cp reporting/scripts/prompts.sh backup/;rm -rf reporting/*; mkdir -p reporting/scripts;mv  backup/* reporting/scripts \
        && cp sspr/scripts/prompts.sh backup/;rm -rf sspr/*; mkdir -p sspr/scripts;mv  backup/* sspr/scripts \
        && cp user_application/scripts/prompts*  backup/;rm -rf user_application/*; mkdir -p user_application/scripts;mv  backup/* user_application/scripts \
        && rm -rf /idm/Identity_Manager_4.8.8_Linux.iso \
        && rm -rf backup;chmod -R 755 /idm/* 

VOLUME ["/config"]
WORKDIR /idm
ENTRYPOINT ["/bin/bash","./create_silent_props.sh" ]
