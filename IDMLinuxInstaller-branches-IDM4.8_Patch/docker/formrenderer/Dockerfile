FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
ARG BUILD_ID
RUN zypper ref -s \
	&& zypper -n --non-interactive in lsof vim wget dos2unix tar gettext gettext-tools net-tools which p7zip-full bc iproute2 ncurses-utils aaa_base unzip glibc-32bit glibc-locale glibc-i18ndata gzip \
	&& zypper cc -a \
	&& mkdir /idm /idmpatch \
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
	&& dos2unix ./install_fr.sh ./configure_fr.sh \
	&& ENABLE_STANDALONE=true IS_ADVANCED_MODE=true debug=y bash -x ./install_fr.sh -slc -ssc -s -f /idm/silent-install.properties \
	&& cd /idmpatch \
	&& chmod -R 755 * \
	&& cd /idmpatch/user_application \
	&& dos2unix ./install_fr.sh ./configure_fr.sh \
	&& ENABLE_STANDALONE=true IS_ADVANCED_MODE=true debug=y bash -x ./install_fr.sh -slc -ssc -s -f /idm/silent-install.properties \
	&& rm -f /idm/Identity_Manager_4.8_Linux.iso /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
	&& rm -rf `find /idm -iname *rpm` \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh} \
	&& rm -f /idmpatch/Identity_Manager_4.8.8_Linux.iso /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf `find /idmpatch -iname *rpm` \
	&& rm /idm/osp/lib/netiq-configutil.jar /idmpatch/osp/lib/netiq-configutil.jar \
	&& echo "alias sed='sed --follow-symlinks'" > ~/.bashrc \
	&& rm -rf /idmpatch/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh}
#EXPOSE 524 389 636 8028 8030
COPY startFR.sh /startFR.sh
COPY commonfunctions.sh /commonfunctions.sh
RUN cd /idm && chmod -R 755 * 

COPY start.sh /start.sh 
RUN chmod 755 /start.sh /startFR.sh /commonfunctions.sh

ENV debug=n
HEALTHCHECK --start-period=30s CMD ps -eaf | grep -E "IgaFormRenderer.sh|nginx: master process|nginx: worker process" | wc -l | grep -E "3|4|5"
ENTRYPOINT ["/bin/bash","/start.sh"]

