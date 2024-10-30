#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

. gettext.sh

initLocale()
{
    TEXTDOMAIN=install
    export TEXTDOMAIN
    TEXTDOMAINDIR=${IDM_INSTALL_HOME}/common/locale
    export TEXTDOMAINDIR
}