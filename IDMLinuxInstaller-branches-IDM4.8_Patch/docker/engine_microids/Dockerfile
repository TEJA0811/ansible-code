#test docker image
##FROM 164.99.163.225/suse/sles12sp2:latest
#FROM 164.99.163.225/sabhay/edir911_sles12sp2:latest
#FROM 164.99.163.225/sabhay/opensuse_edir911
#FROM darksheer/sles12
#FROM edir911

FROM 10.71.32.19:8123/iam-cm/edir911

COPY idmcomponents /idmcomponents
#not installing glibc-locale glibc-i18ndata 
RUN zypper ref -s \
        && zypper -n in wget tar gettext gettext-tools net-tools which p7zip bc iproute2 ncurses-utils aaa_base systemd-sysvinit unzip glibc-32bit curl \
        && mkdir /idm47 \
        && wget -c http://164.99.91.109:8080/view/IDM_4.7.0/view/Install/job/IDMLinuxInstaller_idm4.7.0/lastSuccessfulBuild/artifact/Identity_Manager_4.7_Linux.iso -P /idm47 \
        && 7z x /idm47/Identity_Manager_4.7_Linux.iso -o/idm47 \
        && cd /idm47 \
        && echo UPGRADE_IDM='n' > /idm47/silent-install.properties \
        && echo IS_ADVANCED_EDITION='true' >> /idm47/silent-install.properties \
        && echo INSTALL_ENGINE='true' >> /idm47/silent-install.properties \
        && echo INSTALL_IDVAULT='true' >> /idm47/silent-install.properties \
        && chmod -R 755 * \
		&& cp -r /idmcomponents/install47/common/* /idm47/common \
		&& cp -r /idmcomponents/install47/IDM/* /idm47/IDM \
        && ./install.sh -ssc -s -f /idm47/silent-install.properties \
        && rm -r /idm47/Identity_Manager_4.7_Linux.iso \
        && rm -rf /idm47/IDVault/{eDir_NonRoot.tar.gz,license,res,setup} \
        && rm -rf /idm47/IDM/{packages,utilities} \
        && rm -rf /idm47/{CLE,RHEL-Prerequisite.sh,ReleaseNotes,analyzer,create_silent_props.sh,designer,iManager,install.sh,osp,sspr,reporting,user_application,uninstall.sh} \
        && rm -r `find . -iname *rpm` \
		&& mkdir /idm472 \
		&& cd /idm472 \
		&& wget -c http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.7_Patch/job/Engine/job/IDMLinuxInstaller_IDM4.7_Patch/208/artifact/Identity_Manager_4.7.2_Linux.zip \
		&& unzip *.zip \
		&& echo INSTALL_ENGINE=true > /idm472/silent-install.properties \
		&& echo IDVAULT_SKIP_UPDATE=true >> /idm472/silent-install.properties \
		&& cd /idm472/Identity_Manager_4.7.2_Linux \
		&& cp -r /idmcomponents/update472/common/* /idm472/Identity_Manager_4.7.2_Linux/common \
		&& cp -r /idmcomponents/update472/IDM/* /idm472/Identity_Manager_4.7.2_Linux/IDM \
		&& ./install.sh -s -f /idm472/silent-install.properties \
#		&& cd /idm472/Identity_Manager_4.7.2_Linux/IDVault/setup \
#		&& ./nds-install -u \
		&& cd / \
		&& rm -rf /idm472 \
		&& rm -rf `find /opt/netiq/idm/uninstall_data -iname *rpm` \
		&& mv /idmcomponents/license/ /home/ \
		&& mkdir ldappatch \
		&& cd ldappatch \
		&& wget -c http://blr-idm-jenkins.labs.blr.novell.com:8080/job/IDM4.7_Patch/job/IDMDrivers/job/NetscapeAppShim_IDM4.7_Patch/lastSuccessfulBuild/artifact/NetscapeAppShim_IDM4.7_Patch.zip \
		&& unzip *.zip \
		&& cd NetscapeAppShim_IDM4.7_Patch/linux/ \
		&& rpm -Uvh novell-DXMLldap.rpm \
		&& cd / \
		&& rm -rf /ldappatch \
		&& chmod +x /idmcomponents/remove.sh \
		&& /idmcomponents/remove.sh
				
#EXPOSE 524 389 636 8028 8030
ENV debug=n new_or_add=new treename=Docker_tree context=novell server_name=server1 ip_addr="" eba_enabled=n ncp=524 http=8028 https=8030 ldap=389 ldaps=636
EXPOSE $ncp $ldap $ldaps $http $https
COPY start.sh /start.sh
ENTRYPOINT ["/bin/bash","start.sh"]
#ENTRYPOINT ["/bin/bash"]
