
#use opensuse base image
FROM opensuse:latest
#FROM suse/sles12sp3:latest

#install rpm
COPY netiq-postgresql-9.6.10-1.noarch.rpm /rpm/

#install postgres
RUN  zypper --non-interactive install systemd-sysvinit tar glibc-locale aaa_base \
#  && zypper --non-interactive install aaa_base \
#  && zypper --non-interactive install systemd-sysvinit \
#  && zypper --no-gpg-check addrepo -f http://164.99.162.44:9092 localrepo\
#  && zypper refresh
#  && systemctl daemon-reexec \
#  && zypper --non-interactive --no-gpg-check install netiq-postgresql\
#  && zypper removerepo localrepo\
   && rpm -i /rpm/netiq-postgresql-9.6.10-1.noarch.rpm --nodeps \
   && rm -rf /var/cache/zypp \
   && rm -rf /opt/netiq/idm/postgres/pgAdmin\ 4

COPY configure.sh /configure.sh

RUN chmod 775 /configure.sh\
    && /configure.sh
#open container port to 5432
EXPOSE 5432

VOLUME /opt/netiq/idm/postgres/data

ENTRYPOINT ["/etc/init.d/netiq-postgresql", "start"]
