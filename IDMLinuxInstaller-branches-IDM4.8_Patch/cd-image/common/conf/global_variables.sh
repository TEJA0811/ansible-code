#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

UNATTENDED_INSTALL=0
IS_OS_CHECK_DONE=0
IS_LICENSE_CHECK_DONE=0

IMAN_USER_NAME=novlwww
IMAN_GROUP_NAME=novlwww

#ldap class name to qualifier mapping
o=Organization
ou=organizationalUnit
l=Locality
c=Country
