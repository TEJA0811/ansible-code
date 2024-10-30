#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

install_postgres_bin()
{
        if [ -d "/opt/netiq/idm/postgres/data" ]
        then
            str1=`gettext install "PostgreSQL is already installed."`
            write_and_log "$str1"
        else
	        str1=`gettext install "Installing PostgreSQL database."`
            write_and_log "$str1"
		    ${IDM_INSTALL_HOME}common/packages/postgres/postgresql-9.4.10-1-linux-x64.run --unattendedmodeui none --mode unattended   --prefix /opt/netiq/common/postgre --datadir /opt/netiq/common/postgre/data --servicename idmuserappdb
        fi
}

install_postgres()
{
        if [ -d "/opt/netiq/idm/postgres" ]
        then
            str1=`gettext install "PostgreSQL is already installed."` 
            write_and_log "$str1"
        else
            install_rpm "Postgres database" "*.rpm" "${IDM_INSTALL_HOME}common/packages/postgres" "${MAIN_INSTALL_LOG}" "--nodeps"
            disp_str=`gettext install "Common libraries installation failed. Check logs for more details."`
            check_errs $? $disp_str
        fi
}


