FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
ARG BUILD_ID
RUN zypper ref -s \
	&& zypper -n --non-interactive in vim wget tar gzip lsof gettext gettext-tools net-tools which p7zip-full bc iproute2 ncurses-utils aaa_base unzip glibc-32bit glibc-locale glibc-i18ndata lato-fonts \
	&& zypper cc -a \
	&& mkdir /idm /idmpatch /designerpatch \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM_Trunk/job/Install/job/IDMLinuxInstaller_trunk/lastSuccessfulBuild/artifact/Identity_Manager_4.8_Linux.iso -P /idm \
	&& 7z x /idm/Identity_Manager_4.8_Linux.iso -o/idm \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/IDM4.8_Patch_Pipeline/job/IDMLinuxInstaller_IDM4.8_Patch/$BUILD_ID/artifact/Identity_Manager_4.8.8_Linux.iso -P /idmpatch \
	&& 7z x /idmpatch/Identity_Manager_4.8.8_Linux.iso -o/idmpatch \ 
	&& cd /idmpatch/reporting/packages \
	&& ls > /idm/version.properties \
	&& cd /idmpatch/IDM/packages/engine \
	&& ls >> /idm/version.properties \
	&& cd /idm \
	&& echo UPGRADE_IDM='n' > /idm/silent-install.properties \
	&& echo IS_ADVANCED_EDITION='true' >> /idm/silent-install.properties \
	&& echo INSTALL_REPORTING='true' >> /idm/silent-install.properties \
	&& echo ENABLE_STANDALONE='true' >> /idm/silent-install.properties \
	&& echo IS_ADVANCED_MODE='true' >> /idm/silent-install.properties \
	&& cd /idm \
	&& chmod -R 755 * \
	&& debug=y JRE8CODE_BLOCK=1 bash -x ./install.sh -ssc -s -f /idm/silent-install.properties \
	&& cd /idmpatch \
	&& chmod -R 755 * \
	&& debug=y JRE8CODE_BLOCK=1 bash -x ./install.sh -ssc -s -f /idm/silent-install.properties \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/Designer/job/Designer_4.8_Patches/job/designer_cdimage_linux_LightWeight_4.8.0_Update/lastSuccessfulBuild/artifact/Identity_Manager_Linux_LightWeight_Designer.tar.gz -P /designerpatch \
	&& cd /designerpatch \
	&& tar zxf Identity_Manager_Linux_LightWeight_Designer.tar.gz \
	&& cd designer_install \
	&& unzip -q lightWeightDesigner-linux.gtk.x86_64.zip \
	&& rm -rf /opt/netiq/idm/lightWeightDesigner \
	&& mv lightWeightDesigner /opt/netiq/idm/ \
	&& rm -rf /designerpatch \
	&& rm -f /idm/Identity_Manager_4.8_Linux.iso /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,uninstall.sh,sspr} \
	&& rm -rf /idm/user_application/{u*,sys_req.sh,p*,java.deps,install.sh,driver_conf,activemq.deps} \
	&& rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
	&& rm -r `find /idm -iname *rpm` \
	&& rm -f /idmpatch/Identity_Manager_4.8.8_Linux.iso \
	&& rpm -e netiq-activemq \
	&& rpm -e netiq-osp \
	&& rm -rf /idmpatch/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,uninstall.sh,sspr} /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties* /opt/netiq/idm/apps/tomcat/conf/idm.jks /opt/netiq/idm/activemq /opt/netiq/idm/apps/osp /opt/netiq/idm_backup* \
	&& rm -rf /idmpatch/user_application/{u*,sys_req.sh,p*,java.deps,install.sh,driver_conf,activemq.deps} \
	&& rm /idm/osp/lib/netiq-configutil.jar /idmpatch/osp/lib/netiq-configutil.jar \
	&& echo "alias sed='sed --follow-symlinks'" > ~/.bashrc \
	&& rm -r `find /idmpatch -iname *rpm` \
	# Update /idm folder
	&& cp -rpf /idmpatch/common/scripts/install_common_libs.sh /idm/common/scripts/
#EXPOSE 524 389 636 8028 8030
COPY startreporting.sh /startreporting.sh
COPY start.sh /start.sh
COPY commonfunctions.sh /commonfunctions.sh
COPY rpt_configure-48isopatch.sh /idm/reporting/scripts/rpt_configure.sh
COPY rpt_file_execute-48isopatch.sh /idm/reporting/scripts/rpt_file_execute.sh
RUN chmod 755 /start.sh /startreporting.sh /commonfunctions.sh /idm/reporting/scripts/rpt_configure.sh
ENV debug=n

HEALTHCHECK --start-period=180s CMD ps -eaf | grep -i "server.xml start" | grep -v grep
ENTRYPOINT ["/bin/bash","/start.sh"]
