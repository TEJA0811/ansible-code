#!/bin/sh
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

CATALINA_PID="__CATALINA_BASE__/tomcat.pid"

export JAVA_HOME=__IDM_JRE_HOME__
# Uncomment the osp conf assignment based on the auth type you want to support

# == LDAP and File ==
# OSP_CONF=osp-conf.jar
#
# == FILE only ==
# OSP_CONF=osp-conf-fileonly.jar
#
# == AD and File ==
# OSP_CONF=osp-conf-ad.jar
#
OSP_CONF=__CONFIG_OSP_JAR__

# Snippet to use to turn on trace-level debugging in OSP
# -Dcom.netiq.idm.osp.logging.level=TRACE

# Snippet to turn alter the exception log level
# -Dcom.netiq.idm.exception.log.level=ERROR

export CATALINA_OPTS="-Dcom.netiq.ism.config='__ISM_CONFIG__' -Dcom.netiq.osp.ext-context-file='__OSP_INSTALL_PATH__/lib/$OSP_CONF' -Dcom.netiq.idm.osp.logging.level=WARN -Djava.net.preferIPv4Stack=true  -Dcom.netiq.idm.osp.client.host=__SERVLET_HOSTNAME__ -Dcom.netiq.idm.osp.tenant.logging.naudit.enabled=false -Xms128m -Xmx764m"
