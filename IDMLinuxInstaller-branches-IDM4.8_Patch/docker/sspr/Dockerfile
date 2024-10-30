FROM opensuse/leap:15.2
LABEL "maintainer"="support@microfocus.com"
RUN zypper ref -s \
	&& zypper -n --non-interactive in vim wget tar lsof gettext gettext-tools net-tools which p7zip bc iproute2 ncurses-utils aaa_base unzip glibc-32bit glibc-locale glibc-i18ndata \
	&& mkdir /idm \
	&& wget -c http://blr-iam-jenkins.labs.blr.novell.com:8080/view/IDM_4.7.0/view/Install/job/IDMLinuxInstaller_idm4.8.0/lastSuccessfulBuild/artifact/Identity_Manager_4.8_Linux.iso -P /idm \
	&& 7z x /idm/Identity_Manager_4.8_Linux.iso -o/idm \
	&& cd /idm/ \
	&& chmod -R 755 * \
	&& cd /idm/sspr \
	&& ENABLE_STANDALONE=true IS_ADVANCED_MODE=true ./install.sh -ssc -slc \
	&& rm -f /idm/Identity_Manager_4.8_Linux.iso \
	&& rm -rf /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,IDM,IDVault,reporting,uninstall.sh,user_application,osp} \
	&& rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
	&& rpm -e netiq-jre \
	&& rm -r `find /idm -iname *rpm`
#EXPOSE 524 389 636 8028 8030
COPY startsspr.sh /startsspr.sh
COPY start.sh /start.sh
RUN chmod 755 /start.sh /startsspr.sh
ENV debug=n
ENTRYPOINT ["/bin/bash","start.sh"]

