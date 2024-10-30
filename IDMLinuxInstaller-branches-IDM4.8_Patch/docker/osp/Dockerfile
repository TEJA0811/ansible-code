FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
ARG BUILD_ID
RUN zypper ref -s \
	&& zypper -n --non-interactive in vim wget tar lsof gettext gettext-tools net-tools which p7zip-full bc iproute2 ncurses-utils aaa_base zip unzip glibc-32bit glibc-locale glibc-i18ndata \
	&& zypper cc -a \
	&& mkdir /idm /idmpatch \
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM_Trunk/job/Install/job/IDMLinuxInstaller_trunk/lastSuccessfulBuild/artifact/Identity_Manager_4.8_Linux.iso -P /idm \
	&& 7z x /idm/Identity_Manager_4.8_Linux.iso -o/idm \ 
	&& wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/IDM4.8_Patch_Pipeline/job/IDMLinuxInstaller_IDM4.8_Patch/$BUILD_ID/artifact/Identity_Manager_4.8.8_Linux.iso -P /idmpatch \
	&& 7z x /idmpatch/Identity_Manager_4.8.8_Linux.iso -o/idmpatch \ 
	&& cd /idmpatch/osp/packages \
	&& ls > /idm/version.properties \
	&& cd /idmpatch/IDM/packages/engine \
	&& ls >> /idm/version.properties \
	&& cd /idmpatch \
	&& chmod -R 755 * \
	&& cd /idm \
	&& chmod -R 755 * \
	&& cd /idm/osp \
	&& ENABLE_STANDALONE=true IS_ADVANCED_MODE=true debug=y bash -x ./install.sh -ssc -slc \
	&& cd /idmpatch/osp \
	&& ENABLE_STANDALONE=true IS_ADVANCED_MODE=true debug=y bash -x ./install.sh -ssc -slc \
	&& echo "Copying the 48x patch latest jar to 48 iso and install location" \
	&& cp /idmpatch/osp/lib/netiq-configutil.jar /opt/netiq/idm/apps/osp/lib/netiq-configutil.jar \
	&& cp /idmpatch/osp/lib/netiq-configutil.jar /idm/osp/lib/netiq-configutil.jar \
	&& rm -rf /idmpatch/Identity_Manager_4.8.8_Linux.iso \
        && rm -rf /idmpatch/IDVault /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf /idmpatch/IDM/{packages,utilities} \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /idmpatch/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,osp,sspr,reporting,user_application,uninstall.sh} \
	&& rm -rf `find /idmpatch -iname *rpm` \
	&& rm -f /idm/Identity_Manager_4.8_Linux.iso /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh,sspr} \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /idm/user_application/{u*,sys_req.sh,p*,java.deps,install.sh,driver_conf,activemq.deps} \
	&& rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
	&& echo "alias sed='sed --follow-symlinks'" > ~/.bashrc \
	&& rm -r `find /idm -iname *rpm`
#EXPOSE 524 389 636 8028 8030
COPY startosp.sh /startosp.sh
COPY start.sh /start.sh
COPY commonfunctions.sh /commonfunctions.sh
RUN chmod 755 /start.sh /startosp.sh /commonfunctions.sh
ENV debug=n
HEALTHCHECK --start-period=30s CMD ps -eaf | grep -i "server.xml start" | grep -v grep
ENTRYPOINT ["/bin/bash","start.sh"]

