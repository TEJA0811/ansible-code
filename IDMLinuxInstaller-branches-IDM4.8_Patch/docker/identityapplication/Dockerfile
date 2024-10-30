FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
ARG BUILD_ID
RUN zypper ref -s \
	&& zypper -n --non-interactive in vim lsof wget tar gzip gettext gettext-tools net-tools which p7zip-full bc iproute2 ncurses-utils aaa_base unzip glibc-32bit glibc-locale glibc-i18ndata curl \
	&& zypper cc -a \
	&& mkdir /idm /idmpatch /designerpatch \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM_Trunk/job/Install/job/IDMLinuxInstaller_trunk/lastSuccessfulBuild/artifact/Identity_Manager_4.8_Linux.iso -P /idm \
	&& 7z x /idm/Identity_Manager_4.8_Linux.iso -o/idm \ 
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/IDM4.8_Patch_Pipeline/job/IDMLinuxInstaller_IDM4.8_Patch/$BUILD_ID/artifact/Identity_Manager_4.8.8_Linux.iso -P /idmpatch \
	&& 7z x /idmpatch/Identity_Manager_4.8.8_Linux.iso -o/idmpatch \ 
	&& cd /idmpatch/user_application/packages/ua \
	&& ls > /idm/version.properties \
	&& cd /idmpatch/IDM/packages/engine \
	&& ls >> /idm/version.properties \
	&& cd /idm \
	&& chmod -R 755 * \
	&& echo UPGRADE_IDM='n' > /idm/silent-install.properties \
	&& echo IS_ADVANCED_EDITION='true' >> /idm/silent-install.properties \
	&& echo INSTALL_UA='true' >> /idm/silent-install.properties \
	&& cd /idm/user_application \
	&& FR_STANDALONE=true ENABLE_STANDALONE=true IS_ADVANCED_MODE=true debug=y bash -x ./install.sh -slc -ssc -s -f /idm/silent-install.properties \
	&& cd /idmpatch/user_application \
	&& chmod -R 755 * \
	&& FR_STANDALONE=true ENABLE_STANDALONE=true IS_ADVANCED_MODE=true debug=y bash -x ./install.sh -slc -ssc -s -f /idm/silent-install.properties \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/Designer/job/Designer_4.8_Patches/job/designer_cdimage_linux_LightWeight_4.8.0_Update/lastSuccessfulBuild/artifact/Identity_Manager_Linux_LightWeight_Designer.tar.gz -P /designerpatch \
	&& cd /designerpatch \
	&& tar zxf Identity_Manager_Linux_LightWeight_Designer.tar.gz \
	&& cd designer_install \
	&& unzip -q lightWeightDesigner-linux.gtk.x86_64.zip \
	&& rm -rf /opt/netiq/idm/lightWeightDesigner \
	&& mv lightWeightDesigner /opt/netiq/idm/ \
	&& rm -rf /designerpatch \
	&& cd /idm \
	&& chmod -R 755 * /opt/netiq/idm/apps/tomcat/bin/setenv.sh \
	&& rm -f /idm/Identity_Manager_4.8_Linux.iso /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
	&& rm -rf `find /idm -iname *rpm` \
	&& rm -rf /idmpatch/common/packages/java/*.zip \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh} \
	&& rm -f /idmpatch/Identity_Manager_4.8.8_Linux.iso \
	&& rm -rf `find /idmpatch -iname *rpm` \
	&& rm /idm/osp/lib/netiq-configutil.jar /idmpatch/osp/lib/netiq-configutil.jar \
	&& rpm -e netiq-osp \
	&& rpm -e netiq-ssprconfig \
	&& rpm -e netiq-sspr \
	&& rpm -e netiq-activemq \
	&& echo "alias sed='sed --follow-symlinks'" > ~/.bashrc \
	&& rm -rf /idmpatch/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh} /opt/netiq/idm/apps/tomcat/conf/ism-configuration.properties* /opt/netiq/idm/apps/tomcat/conf/idm.jks /opt/netiq/idm/activemq /opt/netiq/idm/apps/{osp,sspr,sites} /opt/netiq/idm_backup* \
	# Update /idm folder
	&& cp -rpf /idmpatch/common/scripts/install_common_libs.sh /idm/common/scripts/
#EXPOSE 524 389 636 8028 8030
COPY startUA.sh /startUA.sh
RUN cd /idm && chmod -R 755 * /opt/netiq/idm/apps/tomcat/bin/setenv.sh

COPY start.sh /start.sh 
COPY commonfunctions.sh /commonfunctions.sh
COPY ua_configure-48isopatch.sh /idm/user_application/scripts/ua_configure.sh
RUN chmod 755 /start.sh /startUA.sh /commonfunctions.sh /idm/user_application/scripts/ua_configure.sh

ENV debug=n
HEALTHCHECK --start-period=180s CMD ps -eaf | grep -i "server.xml start" | grep -v grep
ENTRYPOINT ["/bin/bash","/start.sh"]

