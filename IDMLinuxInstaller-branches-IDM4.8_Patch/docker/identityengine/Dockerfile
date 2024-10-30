FROM sec-idm-docker.btpartifactory.swinfra.net/iam-cm/edir/929_validated:latest
LABEL "maintainer"="support@microfocus.com"
USER root
ARG BUILD_ID
RUN zypper ref -s \
        && zypper -n in wget tar lsof gettext gettext-tools vim file grep net-tools which p7zip-full bc iproute2 ncurses-utils aaa_base systemd-sysvinit unzip glibc-32bit glibc-locale glibc-i18ndata insserv libcap-progs libncurses5 sudo \
	&& zypper cc -a \
        && mkdir /idm /idmpatch \
        && wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM_Trunk/job/Install/job/IDMLinuxInstaller_trunk/lastSuccessfulBuild/artifact/Identity_Manager_4.8_Linux.iso -P /idm \
        && 7z x /idm/Identity_Manager_4.8_Linux.iso -o/idm \
        && wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/IDM4.8_Patch_Pipeline/job/IDMLinuxInstaller_IDM4.8_Patch/$BUILD_ID/artifact/Identity_Manager_4.8.8_Linux.iso -P /idmpatch \
        && 7z x /idmpatch/Identity_Manager_4.8.8_Linux.iso -o/idmpatch \
        && wget -qc http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.8_Patch/job/Engine/job/idm-containers-utils_IDM4.8_Patch/lastSuccessfulBuild/artifact/final/idm-containers-utils.zip -P /idmpatch \
        && 7z x /idmpatch/idm-containers-utils.zip -o/idmpatch \
        && rm /idmpatch/idm-containers-utils.zip \
        && cd /idm \
        && echo UPGRADE_IDM='n' > /idm/silent-install.properties \
        && echo IS_ADVANCED_EDITION='true' >> /idm/silent-install.properties \
        && echo INSTALL_ENGINE='true' >> /idm/silent-install.properties \
        && echo INSTALL_IDVAULT='true' >> /idm/silent-install.properties \
		&& cd /idmpatch/IDM/packages/engine \
		&& ls > /idm/version.properties \
		&& cd /idm \
        && chmod -R 755 * \
        && debug=y bash -x ./install.sh -ssc -s -f /idm/silent-install.properties \
        && rm -r /idm/Identity_Manager_4.8_Linux.iso \
        && rm -rf /idm/IDVault/{eDir_NonRoot.tar.gz,license,res,setup} /etc/opt/netiq/idm/configure/notconfiguredforcloud \
        && rm -rf /idm/IDM/{packages,utilities} \
        && rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
        && rm -rf /var/opt/netiq/idm/log/idminstall.log /idm/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,osp,sspr,reporting,user_application,uninstall.sh} \
        && rm -r `find . -iname *rpm` \
	&& rm /etc/sudoers \
	&& cd /idmpatch \
        && chmod -R 755 * \
	&& IDVAULT_SKIP_UPDATE=true debug=y bash -x ./install.sh -ssc -s -f /idm/silent-install.properties \
	&& rm -rf /idmpatch/Identity_Manager_4.8.8_Linux.iso \
        && rm -rf /idmpatch/IDVault /etc/opt/netiq/idm/configure/notconfiguredforcloud \
	&& rm -rf /idmpatch/IDM/{packages,utilities} \
        && rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
	&& rm -rf /var/opt/netiq/idm/log/idminstall.log /idmpatch/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,osp,sspr,reporting,user_application,uninstall.sh} \
	&& rm -rf `find /idmpatch -iname *rpm` \
        && echo "Remove the following cp command after fix from xcd jar of UAD" \
        && cp /opt/novell/eDirectory/lib/dirxml/classes/javax.servlet-api*.jar /opt/netiq/common/jre/lib/ \
        && echo "Remove the above cp command after fix from xcd jar of UAD" \
	&& rpm --nodeps -e netiq-DXMLedm \
	&& echo "alias sed='sed --follow-symlinks'" > ~/.bashrc \
	&& cd /

RUN chown -R nds:nds /etc/opt /opt /var/opt /tmp /dev
RUN ln -s /opt/novell/lib64/libnpkit.so.3 /lib64/
RUN echo -e "/opt/novell/eDirectory/lib64\n/opt/novell/eDirectory/lib64/nds-modules\n/opt/novell/lib64\n/opt/novell/eDirectory/lib64/apr\n/opt/novell/eDirectory/lib64/jclnt\n/opt/novell/eDirectory/lib64/nds-modules/jre/lib/amd64\n/opt/novell/eDirectory/lib64/nds-modules/jre/lib/amd64/server\n/opt/novell/eDirectory/lib64/nds-modules/jre/lib/amd64/native_threads\n" > /etc/ld.so.conf.d/ndsd.conf \
    && ldconfig
RUN setcap 'cap_net_bind_service=+ep' /opt/novell/eDirectory/sbin/ndsd
RUN setcap 'cap_net_bind_service=+ep' /opt/novell/eDirectory/bin/ndsconfig
RUN setcap 'cap_net_bind_service=+ep' /opt/novell/eDirectory/bin/dxcmd
COPY start.sh /start.sh
COPY startidm.sh /startidm.sh
RUN chmod 755 /start.sh /startidm.sh

COPY enable_server_self_provisioning.ldif /idm/IDM/ldif
COPY secondary_server_rights.ldif /idm/IDM/ldif

# Base installer patching
COPY base_patch/IDVault/configure.sh /idm/IDVault/configure.sh
RUN chmod 755 /idm/IDVault/configure.sh

HEALTHCHECK --start-period=360s CMD /opt/novell/eDirectory/bin/ndsmanage -a | grep -w ACTIVE
ENTRYPOINT ["/bin/bash","/start.sh"]

