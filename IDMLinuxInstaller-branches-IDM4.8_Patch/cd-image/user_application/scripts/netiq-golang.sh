#!/bin/bash
. gettext.sh
TEXTDOMAIN=install
export TEXTDOMAIN
TEXTDOMAINDIR=/opt/netiq/idm/uninstall_data/common/locale/
export TEXTDOMAINDIR
case $1 in
    start)
    	str1=`gettext install "Starting IGA form renderer backend."`
        echo $str1
        (/opt/netiq/idm/apps/sites/IgaFormRenderer.sh -config /opt/netiq/idm/apps/sites/config.ini -golangPort ___FR_GOLANG_PORT___ start &> /dev/null) &
        ;;
    stop)
    	str1=`gettext install "Stopping IGA form renderer backend"`
        echo $str1
        kill $(lsof -t -i:___FR_GOLANG_PORT___) &> /dev/null
        ;;
    *)
        echo "Hello web app service."
        echo $"Usage $0 {start|stop}"
        exit 1
esac
exit 0
