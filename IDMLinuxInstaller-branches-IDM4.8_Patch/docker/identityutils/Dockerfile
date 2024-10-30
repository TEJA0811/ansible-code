FROM opensuse/leap:15.4
LABEL "maintainer"="support@microfocus.com"
RUN zypper ref -s \
	&& zypper -n in netcat-openbsd net-tools \
        && zypper cc -a

COPY sspr/configure-sspr.sh /configure-sspr.sh
RUN chmod 755 /configure-sspr.sh 

COPY idconsole/configure-id-console.sh /configure-id-console.sh
COPY idconsole/edirapi.conf /edirapi.conf
COPY idconsole/edirapi-osp.conf /edirapi-osp.conf
RUN chmod 755 /configure-id-console.sh /edirapi.conf /edirapi-osp.conf
