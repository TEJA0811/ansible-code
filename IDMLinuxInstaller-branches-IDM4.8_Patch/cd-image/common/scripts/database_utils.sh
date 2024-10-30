#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################


###
# To verify the database connection. 
# $1 - Admin User Name, $2 - Admin Password, $3 - Database host, $4 - Port,  
# $5 - Database Name, $6 - Database Type (eg: "PostgreSQL" or "Oracle" or "SQL Server")
# $7 - Database JDBC jar file path.(eg: /opt/netiq/idm/apps/postgresql/postgresql-9.4.1212.jdbc42.jar)
###

verify_db_connection() {
   
   local IDM_JRE_HOME=/opt/netiq/common/jre/
   if [ ! -d "${IDM_JRE_HOME}" ]
   then
       return 1;
   fi

   local DB_JAR_FILE="${IDM_INSTALL_HOME}/common/lib/dbConnection.jar";
   #Check jar file exist or not.
   if [ -e $DB_JAR_FILE ] 
   then
     echo "$3" | grep -q "ssl=true"
     if [ $? -eq 0 ]
     then
       DBCONURLvar="$3"
       DBCONURLvar=$(echo $DBCONURLvar | sed -e "s#ssl=true#sslmode=require#g")
       "${IDM_JRE_HOME}/bin/java" -jar ${DB_JAR_FILE} $1 $2 "$DBCONURLvar" "$4" $5 | grep -i "successfull" >> $LOG_FILE_NAME
     else
       "${IDM_JRE_HOME}/bin/java" -jar ${DB_JAR_FILE} $1 $2 "$3" "$4" $5 | grep -i "successfull" >> $LOG_FILE_NAME
     fi
   else
     return 1;
   fi 
}

#verify_db_connection postgres novell 164.99.178.47 5432 idmuserappdb PostgreSQL /home/postgresql-9.4.1212.jdbc42.jar 
