#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

database_conncheck()
{
    if [ "$PROD_NAME" = "user_application" ]
    then
            if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ]
            then
                DB_TYPE="Oracle"
                 UA_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${UA_DATABASE_NAME}"
                 WFE_DB_CONNECTION_URL="jdbc:oracle:thin:@${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT}:${WFE_DATABASE_NAME}"
            elif [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
            then
                DB_TYPE="SQL Server"
                UA_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${UA_DATABASE_NAME}"
                WFE_DB_CONNECTION_URL="jdbc:sqlserver://${UA_WFE_DB_HOST}:${UA_WFE_DB_PORT};DatabaseName=${WFE_DATABASE_NAME}"
            fi
            if [ "${UA_WFE_DB_PLATFORM_OPTION}" == "oracle" ] || [ "${UA_WFE_DB_PLATFORM_OPTION}" == "mssql" ]
            then
                #verify_db_connection ${UA_WFE_DATABASE_USER} ${UA_WFE_DATABASE_PWD} ${UA_WFE_DB_HOST} ${UA_WFE_DB_PORT} ${UA_DATABASE_NAME} ${DB_TYPE} ${UA_WFE_DB_JDBC_DRIVER_JAR}
                verify_db_connection ${UA_WFE_DATABASE_USER} ${UA_WFE_DATABASE_PWD} "${UA_DB_CONNECTION_URL}" "${DB_TYPE}" ${UA_WFE_DB_JDBC_DRIVER_JAR}
		UA_DB_CONN_RET=$?
                verify_db_connection ${UA_WFE_DATABASE_USER} ${UA_WFE_DATABASE_PWD} "${WFE_DB_CONNECTION_URL}" "${DB_TYPE}" ${UA_WFE_DB_JDBC_DRIVER_JAR}
		WFE_DB_CONN_RET=$?
                DB_CONN_RET=0
		if [ $UA_DB_CONN_RET -eq 1 ] || [ $WFE_DB_CONN_RET -eq 1 ]
		then
			DB_CONN_RET=1
		fi

                if [ $DB_CONN_RET -eq 1 ]
                then
                    disp_str=`gettext install "Connection to database failed. Check whether database is running or parameters provided is valid. Run upgrade after correcting problem."`
                    write_and_log "$disp_str"
                exit
                else
                    disp_str=`gettext install "Database connection successful."`
                    write_and_log "$disp_str"
                fi
            fi
    elif [ "$PROD_NAME" = "reporting" ]
    then
    	    if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ]
	    then
                DB_TYPE="Oracle"
                if [ "${RPT_ORACLE_DATABASE_TYPE}" == "service" ]
                then
                   RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}/${RPT_DATABASE_NAME}"
                elif [ "${RPT_ORACLE_DATABASE_TYPE}" == "sid" ]
                then
                   RPT_DATABASE_CONNECTION_URL="jdbc:oracle:thin:@${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT}:${RPT_DATABASE_NAME}"
                fi
	    elif [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
	    then
                DB_TYPE="SQL Server"
                RPT_DATABASE_CONNECTION_URL="jdbc:sqlserver://${RPT_DATABASE_HOST}:${RPT_DATABASE_PORT};DatabaseName=${RPT_DATABASE_NAME}"
	    fi
            if [ "${RPT_DATABASE_PLATFORM_OPTION}" == "oracle" ] || [ "${RPT_DATABASE_PLATFORM_OPTION}" == "mssql" ]
            then
                verify_db_connection ${RPT_DATABASE_USER} ${RPT_DATABASE_SHARE_PASSWORD} "${RPT_DATABASE_CONNECTION_URL}" "${DB_TYPE}" ${RPT_DATABASE_JDBC_DRIVER_JAR}
                DB_CONN_RET=$?
                if [ $DB_CONN_RET -eq 1 ]
                then
                    disp_str=`gettext install "Connection to database failed. Check database is running or parameters provided is valid. Run configure after correcting problem."`
                    write_and_log "$disp_str"
                    exit
                else
                    disp_str=`gettext install "Database connection successful."`
                    write_and_log "$disp_str"
                fi
            fi
    fi
}
