#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

if [ -n "${1}" ]
then
    RPT_DATABASE_SHARE_PASSWORD="${1}"
else
    echo "Provide Identity Reporting database account password (shared) as parameter"
    exit
fi

RPT_JRE_HOME="/opt/netiq/common/jre/"
str1="Performing liquibase update for : IdmDcsDataDropViews.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema-DCS.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-01-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataDropViews.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 
str1="Performing liquibase update for : IdmRptCfgDropViews.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema-DCS.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-01-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgDropViews.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 

"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_data -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-001-run-as-idm_rpt_data.sql"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_cfg -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-01-run-as-idm_rpt_cfg.sql"

str1="Performing liquibase update for : IdmRptCfgSchemaChangeLog.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -Ddefault.datasource.name="Installed Database" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-02-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptCfgSchemaChangeLog.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 

"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_cfg -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-02-run-as-idm_rpt_cfg.sql"

str1="Performing liquibase update for : IdmRptDataSchemaChangeLog.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema-DCS.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-03-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataSchemaChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 

"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_data -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-03-run-as-idm_rpt_data.sql"

str1="Performing liquibase update for : IdmRptDataOTBDataChangeLog.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema-DCS.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-04-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmRptDataOTBDataChangeLog.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 

"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_data -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-04-run-as-idm_rpt_data.sql"

str1="Performing liquibase update for : IdmDcsDataViewChangeLogNew.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema-DCS.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-05-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataViewChangeLogNew.xml --defaultSchemaName=idm_rpt_data --username=idm_rpt_data --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 

"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_data -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-05-run-as-idm_rpt_data.sql"

str1="Performing liquibase update for : IdmDcsDataGrantPrivileges.xml"
echo "$str1"
"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/DbSchema-DCS.jar:/opt/netiq/idm/apps/IDMReporting/DbSchema.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__:/opt/netiq/idm/apps/IDMReporting/liquibase.jar:__RPT_CONFIG_HOME_PERSIST_JAR__" liquibase.integration.commandline.Main --url="__RPT_DATABASE_CONNECTION_URL__" --logFile="/var/opt/netiq/idm/log/RptDb-06-log.out" --logLevel=info --outputDefaultCatalog=true --outputDefaultSchema=true --changeLogFile=IdmDcsDataGrantPrivileges.xml --defaultSchemaName=idm_rpt_cfg --username=idm_rpt_cfg --password=${RPT_DATABASE_SHARE_PASSWORD}  clearCheckSums 

"${RPT_JRE_HOME}bin/java" -classpath "/opt/netiq/idm/apps/IDMReporting/idmjdbc.jar:__RPT_DATABASE_JDBC_DRIVER_JAR__" com.netiq.persist.util.JdbcExecuteUpdate -d org.postgresql.Driver -j "__RPT_DATABASE_CONNECTION_URL__" -u idm_rpt_cfg -p ${RPT_DATABASE_SHARE_PASSWORD} -f "/opt/netiq/idm/apps/IDMReporting/sql/DbUpdate-06-run-as-idm_rpt_cfg.sql"
