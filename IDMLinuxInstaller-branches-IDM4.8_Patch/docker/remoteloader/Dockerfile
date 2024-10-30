FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
ARG BUILD_ID
RUN zypper ref -s \
	&& zypper -n --non-interactive in wget tar gettext gettext-tools net-tools which p7zip-full bc iproute2 ncurses-utils aaa_base vim \
	&& zypper cc -a \
	&& mkdir /idm /idmpatch \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM_Trunk/job/Install/job/IDMLinuxInstaller_trunk/lastSuccessfulBuild/artifact/Identity_Manager_4.8_Linux.iso -P /idm \
	&& 7z x /idm/Identity_Manager_4.8_Linux.iso -o/idm \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/IDM4.8_Patch_Pipeline/job/IDMLinuxInstaller_IDM4.8_Patch/$BUILD_ID/artifact/Identity_Manager_4.8.8_Linux.iso -P /idmpatch \
	&& 7z x /idmpatch/Identity_Manager_4.8.8_Linux.iso -o/idmpatch \ 
	&& cd /idmpatch/IDM/packages/rl/x86_64/ \
	&& ls > /idm/version.properties \
	&& cd /idmpatch/IDM/packages/engine \
	&& ls >> /idm/version.properties \
	&& cd /idm \
	&& echo UPGRADE_IDM='n' > /idm/silent-install.properties \
	&& echo INSTALL_RL='true' >> /idm/silent-install.properties \
	&& chmod -R 755 * \
	&& debug=y bash -x ./install.sh -ssc -s -f /idm/silent-install.properties \
	&& cd /idmpatch \
	&& chmod -R 755 * \
	&& debug=y bash -x ./install.sh -ssc -s -f /idm/silent-install.properties \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /etc/opt/netiq/idm/configure/notconfiguredforcloud /opt/netiq/idm/uninstall_data \
	&& rm -f /idm/Identity_Manager_4.8_Linux.iso \
	&& rm -f /idmpatch/Identity_Manager_4.8.8_Linux.iso \
        && rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
        && rm -rf `find /idm -iname *rpm` \
        && rm -rf `find /idmpatch -iname *rpm` \
	&& echo "alias sed='sed --follow-symlinks'" > ~/.bashrc \
	&& rpm -e nici64 \
        && rm -rf /var/opt/netiq/idm/log/idminstall.log /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh} \
	&& rm /idm/osp/lib/netiq-configutil.jar /idmpatch/osp/lib/netiq-configutil.jar \
	&& rpm --nodeps -e netiq-DXMLedm \
        && rm -rf /idmpatch/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh}

COPY start.sh /start.sh
COPY startRL.sh /startRL.sh

RUN chmod 755 /start.sh /startRL.sh

VOLUME ["/config"]

ENTRYPOINT ["/start.sh"]

