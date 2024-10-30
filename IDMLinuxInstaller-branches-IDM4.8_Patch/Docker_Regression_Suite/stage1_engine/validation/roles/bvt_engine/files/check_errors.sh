touch error_install_configure.log
if [ $(grep -ir "ERROR" nds-install.log)]
then
       echo "nds-install.log has errors - FAIL" >> error_install_configure.log
else
       echo "nds-install.log has no errors - PASS" >> error_install_configure.log
fi
if [ $(grep -ir "ERROR" ndsd.log)]
then
       echo "ndsd.log has errors - FAIL" >> error_install_configure.log
else
       echo "ndsd.log has no errors - PASS" >> error_install_configure.log
fi
if [ $(grep -ir "ERROR" idminstall.log)]
then
       echo "idminstall.log has errors - FAIL" >> error_install_configure.log
else
       echo "idminstall.log has no errors - PASS" >> error_install_configure.log
fi
if [ $(grep -ir "ERROR" idmconfigure.log)]
then
       echo "idmconfigure.log has errors - FAIL" >> error_install_configure.log
else
       echo "idmconfigure.log has no errors - PASS" >> error_install_configure.log
fi
if [ $(grep -ir "ERROR" idmupgrade.log)]
then
       echo "idmupgrade.log has errors - FAIL" >> error_install_configure.log
else
       echo "idmupgrade.log has no errors - PASS" >> error_install_configure.log
fi

