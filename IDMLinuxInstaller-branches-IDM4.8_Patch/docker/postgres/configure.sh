#! /bin/bash
export POSTGRES_HOME=/opt/netiq/idm/postgres/

mkdir ${POSTGRES_HOME}/data

mkdir -p /home/users/postgres

chown -R postgres:postgres ${POSTGRES_HOME}

chown -R postgres:postgres /home/users/postgres

mkdir /home/postgres

chown -R postgres:postgres /home/postgres

su -s /bin/sh - postgres -c "${POSTGRES_HOME}/bin/initdb -D ${POSTGRES_HOME}/data"

mkdir ${POSTGRES_HOME}/data/pg_log

chown -R postgres:postgres ${POSTGRES_HOME}

echo "host    all             all       0.0.0.0/0    trust" >> ${POSTGRES_HOME}/data/pg_hba.conf

echo "listen_addresses = '*'" >> ${POSTGRES_HOME}/data/postgresql.conf

cp ${POSTGRES_HOME}/data/pg_hba.conf ${POSTGRES_HOME}/data/pg_hba.conf.idmcfg

#systemctl stop netiq-postgresql
/etc/init.d/netiq-postgresql stop

#systemctl start netiq-postgresql
#/etc/init.d/netiq-postgresql start


