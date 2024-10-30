#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

# copy and paste this command to your command prompt
# and execute the command before changing context name
__IDM_JRE_HOME_/bin/java -cp "__UA_CONFIG_HOME__/liquibase.jar:__UA_CONFIG_HOME__/liquibase/lib/*" liquibase.integration.commandline.Main --classpath="__UA_DB_JDBC_DRIVER_JAR__:__IDM_TOMCAT_HOME__/webapps/__UA_APP_CTX__.war" --driver=__UA_DB_DRIVER__ --url="__UA_DB_CONNECTION_URL__" --username=******** --password=******** --contexts="prov,updatedb" --logLevel=debug clearCheckSums
__IDM_JRE_HOME_/bin/java -cp "__UA_CONFIG_HOME__/liquibase.jar:__UA_CONFIG_HOME__/liquibase/lib/*" liquibase.integration.commandline.Main --classpath="__UA_DB_JDBC_DRIVER_JAR__:__IDM_TOMCAT_HOME__/webapps/__WFE_APP_CTX__.war" --driver=__UA_DB_DRIVER__ --url="__WFE_DB_CONNECTION_URL__" --username=******** --password=******** --contexts="prov,updatedb" --logLevel=debug clearCheckSums
