#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

# copy and paste or execute this script
# before changing context name
# Substitute your new context where indicated
__IDM_JRE_HOME_/bin/java -Xms256m -Xmx256m -Dwar.context.name=[New Context Here] -Ddriver.dn=[UA Driver DN] -cp "__UA_CONFIG_HOME__/liquibase.jar:__UA_CONFIG_HOME__/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=__UA_DB_DRIVER__ --classpath="__UA_DB_JDBC_DRIVER_JAR__:__IDM_TOMCAT_HOME__/webapps/__UA_APP_CTX__.war" --changeLogFile=UpdateProducerId.xml --url="__UA_DB_CONNECTION_URL__" --contexts="prov,updatedb" --logLevel=debug --username=***** --password=****** update
__IDM_JRE_HOME_/bin/java -Xms256m -Xmx256m -Dwar.context.name=[New Context Here] -Ddriver.dn=[UA Driver DN] -cp "__UA_CONFIG_HOME__/liquibase.jar:__UA_CONFIG_HOME__/liquibase/lib/*" liquibase.integration.commandline.Main --databaseClass=${UA_DB_DRIVER_CLASS} --driver=__UA_DB_DRIVER__ --classpath="__UA_DB_JDBC_DRIVER_JAR__:__IDM_TOMCAT_HOME__/webapps/__WFE_APP_CTX__.war" --changeLogFile=UpdateProducerId.xml --url="__WFE_DB_CONNECTION_URL__" --contexts="prov,updatedb" --logLevel=debug --username=***** --password=****** update
